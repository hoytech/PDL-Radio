package PDL::Radio::RTTY;

use common::sense;

use base qw(PDL::Radio::Sound);

use PDL;
use PDL::Radio;
use PDL::Radio::Code::Baudot;


sub new {
  my ($class, %args) = @_;

  my $self = \%args;
  bless $self, $class;

  $self->init;

  $self->{freq} //= 1000;

  die "must pass in a msg" if !defined $self->{msg};

  $self->{msg} = uc $self->{msg};

  return $self;
}



sub render {
  my ($self, $cb) = @_;

  my $freq = $self->{freq};
  my $freq_shift = 170;
  my $freq1 = $freq - ($freq_shift / 2);
  my $freq2 = $freq + ($freq_shift / 2);

  my $baud = 45.45;
  my $stop_bit_len = 1.5;

  my $symlen = 1 / ($baud + 0.5);

  my $current_phase1 = 0;
  my $current_phase2 = 0;

  foreach my $char (split //, $self->{msg}) {
    my $osc = sequence(0);

    $osc = $osc->append($self->sine($symlen, $freq1, $current_phase1)); ## start bit
    $current_phase1 += 2*PI*$symlen*$freq1;
    $current_phase2 += 2*PI*$symlen*$freq1;

    my $bits = $PDL::Radio::Code::Baudot::letters_lookup->{$char};
    $bits = 0 if !defined $char;

    for (1..5) {
      my $bit = $bits & 1;
      $bits >>= 1;

      if ($bit) {
        $osc = $osc->append($self->sine($symlen, $freq2, $current_phase2));
        $current_phase1 += 2*PI*$symlen*($freq2);
        $current_phase2 += 2*PI*$symlen*($freq2);
      } else {
        $osc = $osc->append($self->sine($symlen, $freq1, $current_phase1));
        $current_phase1 += 2*PI*$symlen*$freq1;
        $current_phase2 += 2*PI*$symlen*$freq1;
      }
    }

    $osc = $osc->append($self->sine($symlen * $stop_bit_len, $freq2, $current_phase2)); ## stop bit
    $current_phase1 += 2*PI*($symlen * $stop_bit_len)*($freq2);
    $current_phase2 += 2*PI*($symlen * $stop_bit_len)*($freq2);

    $cb->($osc);
  }
}



1;
