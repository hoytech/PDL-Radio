package PDL::Sound;

use common::sense;

our $VERSION = '0.001';


use PDL;

use PDL::Sound::Varicode;
use PDL::Sound::MorseCode;
use PDL::Sound::Baudot;


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(PI);


sub PI () { 3.14159265358979 }


sub new {
  my ($class, %args) = @_;

  my $self = \%args;
  bless $self, $class;

  $self->{sample_rate} ||= 8000;
  $self->{volume} ||= 5000;

  open(my $fh, '|-:raw', "pacat --stream-name fldigi --format s16ne --rate $self->{sample_rate} --channels 1")
    || die "couldn't run pacat (install pulse-audio?): $!";

  $self->{fh} = $fh;

  return $self;
}


sub play_raw {
  my ($self, $osc) = @_;

  my $fh = $self->{fh};

  $osc *= $self->{volume};

  print $fh ${ $osc->convert(short)->get_dataref };

  return $self;
}

sub play {
  my ($self, $first, @args) = @_;

  my $osc;

  if (ref $first) {
    $osc = $first;
  } else {
    if ($first eq 'psk') {
      $self->_psk(1, @args);
      return;
    } elsif ($first eq 'cw') {
      $self->_cw(1, @args);
      return;
    } elsif ($first eq 'rtty') {
      $self->_rtty(1, @args);
      return;
    } else {
      $osc = $self->$first(@args);
    }
  }

  $self->play_raw($osc);

  return $self;
}

sub plot {
  my ($self, $first, @args) = @_;

  my $osc;

  if (ref $first) {
    $osc = $first;
  } else {
    $osc = $self->$first(@args);
  }

  #use PDL::Graphics::PGPLOT; dev('/XSERVE'); line($osc);
  use PDL::Graphics::Gnuplot; gplot($osc, { terminal => 'x11' }); sleep 100000;

  return $self;
}


sub sine {
  my ($self, $duration, $freq, $phase) = @_;

  return sin(2*PI * sequence($duration*$self->{sample_rate}) * $freq/$self->{sample_rate} + $phase);
}

sub square {
  my ($self, @args) = @_;

  my $osc = $self->sine(@args);

  $osc = ($osc < 0) * 2 - 1;

  return $osc;
}

sub sawtooth {
  my ($self, $duration, $freq, $phase) = @_;

  return ((sequence($duration*$self->{sample_rate}) * $freq/$self->{sample_rate}) % 1 - 0.5) * 2;
}



# Useful test-case: ASCII "3" is 00110011 binary which is "ee" in varicode

sub psk {
  my $self = shift;
  return $self->_psk(0, @_);
}

sub psk_raw {
  my ($self, $play, $freq, $bits, $num_bits) = @_;

  my $output = sequence(0) if !$play;

  my $symbol_dur = 0.032; # PSK-31
  my $symbol_samples = $symbol_dur * $self->{sample_rate};

  my $current_phase = 0;

  my $raised_cosine_filter = cos(2 * PI * sequence($symbol_samples) / $symbol_samples) * 0.5 + 0.5;

  for my $i (0 .. $num_bits) {
    my $osc;

    if (vec($bits, $i, 1)) {
      $osc = $self->sine($symbol_dur, $freq, $current_phase);

      $current_phase += 2*PI*$symbol_dur*$freq;
    } else {
      $osc = $self->sine($symbol_dur/2, $freq, $current_phase)
                  ->append($self->sine($symbol_dur/2, $freq, $current_phase + (PI*$symbol_dur*$freq) + PI));

      $osc *= $raised_cosine_filter;

      $current_phase += PI + (2*PI*$symbol_dur*$freq);
    }

    if ($play) {
      $self->play_raw($osc);
    } else {
      $output = $output->append($osc);
    }
  }

  if ($play) {
    return $self;
  } else {
    return $output;
  }
}

sub _psk {
  my ($self, $play, $freq, $msg) = @_;

  my $bits;
  my $num_bits = 32;

  foreach my $char (split //, $msg) {
    my $symbol = $PDL::Sound::Varicode::table->[ord($char)];
    foreach my $bit (split //, $symbol) {
      vec($bits, $num_bits, 1) = $bit;
      $num_bits++;
    }
    $num_bits += 2;
  }

  vec($bits, $num_bits++, 1) = 1 for (1..32);

  return $self->psk_raw($play, $freq, $bits, $num_bits);
}



sub cw {
  my $self = shift;
  return $self->_cw(0, @_);
}

sub _cw {
  my ($self, $play, $freq, $wpm, $msg) = @_;

  $msg = uc $msg;

  my $output = sequence(0) if !$play;

  my $symlen = 60 / ($wpm * 50); ## A "standard" word is 50 elements long (ie "PARIS")

  foreach my $char (split //, $msg) {
    my $code = $PDL::Sound::MorseCode::table->{$char};
    $code = ' ' if !defined $code;

    my $osc = sequence(0);

    foreach my $sym (split //, $code) {
      if ($sym eq '.') {
        $osc = $osc->append($self->sine($symlen, $freq))
                   ->append($self->sine($symlen, $freq) * 0);
      } elsif ($sym eq '-') {
        $osc = $osc->append($self->sine($symlen * 3, $freq))
                   ->append($self->sine($symlen, $freq) * 0);
      } else {
        $osc = $osc->append($self->sine($symlen * 4, $freq) * 0);
      }
    }

    $osc = $osc->append($self->sine($symlen * 2, $freq) * 0);

    if ($play) {
      $self->play_raw($osc);
    } else {
      $output = $output->append($osc);
    }
  }

  if ($play) {
    return $self;
  } else {
    return $output;
  }
}


sub rtty {
  my $self = shift;
  return $self->_rtty(0, @_);
}

sub _rtty {
  my ($self, $play, $freq, $msg) = @_;

  $msg = uc $msg;

  my $output = sequence(0) if !$play;

  my $baud = 45.45;
  my $freq_shift = 170;
  my $stop_bit_len = 1.5;

  my $symlen = 1 / ($baud + 0.5);

  my $current_phase1 = 0;
  my $current_phase2 = 0;

  foreach my $char (split //, $msg) {
    my $osc = sequence(0);

    $osc = $osc->append($self->sine($symlen, $freq, $current_phase1)); ## start bit
    $current_phase1 += 2*PI*$symlen*$freq;
    $current_phase2 += 2*PI*$symlen*$freq;

    my $bits = $PDL::Sound::Baudot::letters_lookup->{$char};
    $bits = 0 if !defined $char;

    for (1..5) {
      my $bit = $bits & 1;
      $bits >>= 1;

      if ($bit) {
        $osc = $osc->append($self->sine($symlen, $freq + $freq_shift, $current_phase2));
        $current_phase1 += 2*PI*$symlen*($freq + $freq_shift);
        $current_phase2 += 2*PI*$symlen*($freq + $freq_shift);
      } else {
        $osc = $osc->append($self->sine($symlen, $freq, $current_phase1));
        $current_phase1 += 2*PI*$symlen*$freq;
        $current_phase2 += 2*PI*$symlen*$freq;
      }
    }

    $osc = $osc->append($self->sine($symlen * $stop_bit_len, $freq + $freq_shift, $current_phase2)); ## stop bit
    $current_phase1 += 2*PI*($symlen * $stop_bit_len)*($freq + $freq_shift);
    $current_phase2 += 2*PI*($symlen * $stop_bit_len)*($freq + $freq_shift);

    if ($play) {
      $self->play_raw($osc);
    } else {
      $output = $output->append($osc);
    }
  }

  if ($play) {
    return $self;
  } else {
    return $output;
  }
}



1;


__END__


=encoding utf-8

=head1 NAME

PDL::Sound - Sound interface for PDL::Sound

=head1 SYNOPSIS

    ## Play 1000 Hz sine wave for 5 seconds:
    PDL::Sound->new->play("sine", 5, 1000);

    ## Play .5 seconds of a sine wave, phase shift 180 degrees, play another .5:
    PDL::Sound->new->play("sine", .5, 1000)
                   ->play("sine", .5, 1000, PI);

    ## Plot 5 periods of a sawtooth wave:
    PDL::Sound->new->plot("sawtooth", 5, 1);

    ## Play PSK-31 encoded message
    PDL::Sound->new->play("psk", 1000, "hello world!");

=head1 DESCRIPTION

This is a work-in-progress library for generating sound data and playing it through L<Pulse Audio|http://www.freedesktop.org/wiki/Software/PulseAudio/>. Pulse Audio makes redirecting the audio output to programs like L<fldigi|http://www.w1hkj.com/Fldigi.html> really easy.

=head1 SEE ALSO

L<The PDL::Sound github repo|https://github.com/hoytech/PDL-Sound>

L<PDL::Audio> is very similar to this module except that it interfaces to sndlib where this module interfaces to pulseaudio. L<PDL::Audio> is a pain to setup and I couldn't figure out how to send data to fldigi. Also, L<Pulse::Audio> doesn't seem to be on CPAN anymore?

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012-2013 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut
