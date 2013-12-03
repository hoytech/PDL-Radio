package PDL::Radio::PSK;

use common::sense;

use base qw(PDL::Radio::Modem);

use PDL;
use PDL::Radio;
use PDL::Radio::Code::Varicode;


sub new {
  my ($class, %args) = @_;

  my $self = \%args;
  bless $self, $class;

  $self->init;

  $self->{freq} //= 1000;

  return $self;
}



sub encode_msg {
  my ($self, $msg) = @_;

  my ($bits, $num_bits);

  $num_bits += 32;

  foreach my $char (split //, $msg) {
    my $symbol = $PDL::Radio::Code::Varicode::table->[ord($char)];
    foreach my $bit (split //, $symbol) {
      vec($bits, $num_bits, 1) = $bit;
      $num_bits++;
    }
    $num_bits += 2;
  }

  vec($bits, $num_bits++, 1) = 1 for (1..32);

  return ($bits, $num_bits);
}



sub render {
  my ($self, @args) = @_;

  my $cb = pop @args;

  my ($bits, $num_bits);

  if (@args == 2) {
    ($bits, $num_bits) = @args;
  } else {
    ($bits, $num_bits) = $self->encode_msg($args[0]);
  }

  my $symbol_dur = 0.032; # PSK-31
  my $symbol_samples = $symbol_dur * $self->{sample_rate};

  my $current_phase = 0;

  my $raised_cosine_filter = cos(PI * sequence($symbol_samples) / $symbol_samples) * 0.5 + 0.5;

  for my $i (0 .. ($num_bits-1)) {
    my $osc;

    if (vec($bits, $i, 1)) {
      $osc = $self->sine($symbol_dur, $self->{freq}, $current_phase);

      $current_phase += 2*PI*$symbol_dur*$self->{freq};
    } else {
      $osc = ($self->sine($symbol_dur, $self->{freq}, $current_phase) * $raised_cosine_filter) +
             ($self->sine($symbol_dur, $self->{freq}, $current_phase + (PI*$symbol_dur*$self->{freq}) + PI) * (1 - $raised_cosine_filter));

      $current_phase += PI + (2*PI*$symbol_dur*$self->{freq});
    }

    $cb->($osc);
  }
}


1;
