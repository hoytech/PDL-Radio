package PDL::Radio::RTTY;

use common::sense;

use base qw(PDL::Radio::Modem);

use PDL;
use PDL::Radio;
use PDL::Radio::Code::Baudot;


## FIXME: Softer keying!


sub new {
  my ($class, %args) = @_;

  my $self = \%args;
  bless $self, $class;

  $self->init;

  $self->{freq} //= 1000;
  $self->{freq_shift} //= 170;
  $self->{baud} //= 45.45;
  $self->{stop_bit_len} //= 1.5;

  return $self;
}



sub render {
  my ($self, $msg, $cb) = @_;

  $msg = uc $msg;

  ## Hack: Use \x01 for FIGS and \x02 for LTRS
  $msg =~ s/([^A-Z\r\n ]+)/\x01$1\x02/g;

  my $freq = $self->{freq};
  my $freq_shift = $self->{freq_shift};
  my $freq1 = $freq - ($freq_shift / 2);
  my $freq2 = $freq + ($freq_shift / 2);

  my $baud = $self->{baud};
  my $stop_bit_len = $self->{stop_bit_len};

  my $symlen = 1 / ($baud + 0.5);

  my $current_phase1 = 0;
  my $current_phase2 = 0;

  foreach my $char (split //, $msg) {
    my $osc = sequence(0);

    $osc = $osc->append($self->sine($symlen, $freq1, $current_phase1)); ## start bit
    $current_phase1 += 2*PI*$symlen*$freq1;
    $current_phase2 += 2*PI*$symlen*$freq1;

    my $bits = $PDL::Radio::Code::Baudot::letters_lookup->{$char} //
               $PDL::Radio::Code::Baudot::figures_lookup->{$char} //
               ($char eq "\x01" ? $PDL::Radio::Code::Baudot::letters_lookup->{FIGS} :
                $char eq "\x02" ? $PDL::Radio::Code::Baudot::letters_lookup->{LTRS} :
                0);

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
