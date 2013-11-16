package PDL::Sound;

use common::sense;

our $VERSION = '0.001';


use PDL;

use PDL::Sound::Varicode;


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
  use PDL::Graphics::Gnuplot; gplot($osc); sleep 100000;

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

sub _psk {
  my ($self, $play, $freq, $msg) = @_;

  my $output = sequence(0) if !$play;

  my $bits;
  my $num_bits = 2;

  foreach my $char (split //, $msg) {
    my $symbol = $PDL::Sound::Varicode::table->[ord($char)];
    foreach my $bit (split //, $symbol) {
      vec($bits, $num_bits, 1) = $bit;
      $num_bits++;
    }
    $num_bits += 2;
  }

  my $raised_cosine_filter = cos(2 * PI * sequence(256) / 256) * 0.5 + 0.5;

  my $current_phase = 0;

  for my $i (0 .. $num_bits) {
    my $osc;

    my $dur = 0.032;

    if (vec($bits, $i, 1)) {
      $osc = $self->sine($dur, $freq, $current_phase);
    } else {
      $osc = $self->sine($dur/2, $freq, $current_phase)->append($self->sine($dur/2, $freq, $current_phase + PI))
             * $raised_cosine_filter;

      $current_phase += PI;
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
