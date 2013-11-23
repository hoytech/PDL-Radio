package PDL::Radio::PSK;

use common::sense;

use base qw(PDL::Radio::Sound);

use PDL;
use PDL::Radio;
use PDL::Radio::Code::Varicode;


sub new {
  my ($class, %args) = @_;

  my $self = \%args;
  bless $self, $class;


  $self->init;


  ## Check params

  $self->{freq} //= 1000;

  if (defined $self->{msg} || defined $self->{bits}) {
    die "can't define both msg and bits"
      if defined $self->{msg} && defined $self->{bits};

    die "must define num_bits"
      if defined $self->{bits} && !defined $self->{num_bits};
  } else {
    die "must define either msg or bits+num_bits";
  }



  ## Encode msg

  if (defined $self->{msg}) {
    $self->encode_msg;
  }


  return $self;
}



sub encode_msg {
  my ($self) = @_;

  $self->{num_bits} += 32;

  foreach my $char (split //, $self->{msg}) {
    my $symbol = $PDL::Radio::Code::Varicode::table->[ord($char)];
    foreach my $bit (split //, $symbol) {
      vec($self->{bits}, $self->{num_bits}, 1) = $bit;
      $self->{num_bits}++;
    }
    $self->{num_bits} += 2;
  }

  vec($self->{bits}, $self->{num_bits}++, 1) = 1 for (1..32);
}



sub render {
  my ($self, $cb) = @_;

  my $symbol_dur = 0.032; # PSK-31
  my $symbol_samples = $symbol_dur * $self->{sample_rate};

  my $current_phase = 0;

  my $raised_cosine_filter = cos(2 * PI * sequence($symbol_samples) / $symbol_samples) * 0.5 + 0.5;

  for my $i (0 .. $self->{num_bits}) {
    my $osc;

    if (vec($self->{bits}, $i, 1)) {
      $osc = $self->sine($symbol_dur, $self->{freq}, $current_phase);

      $current_phase += 2*PI*$symbol_dur*$self->{freq};
    } else {
      $osc = $self->sine($symbol_dur/2, $self->{freq}, $current_phase)
                  ->append($self->sine($symbol_dur/2, $self->{freq}, $current_phase + (PI*$symbol_dur*$self->{freq}) + PI));

      $osc *= $raised_cosine_filter;

      $current_phase += PI + (2*PI*$symbol_dur*$self->{freq});
    }

    $cb->($osc);
  }
}


1;
