package PDL::Radio::CW;

use common::sense;

use base qw(PDL::Radio::Sound);

use PDL;
use PDL::Radio;
use PDL::Radio::Code::Morse;


sub new {
  my ($class, %args) = @_;

  my $self = \%args;
  bless $self, $class;


  $self->init;


  $self->{freq} //= 1000;
  $self->{wpm} //= 15;

  die "must pass in a msg" if !defined $self->{msg};

  $self->{msg} = uc $self->{msg};

  return $self;
}



sub render {
  my ($self, $cb) = @_;

  my $freq = $self->{freq};

  my $symlen = 60 / ($self->{wpm} * 50); ## A "standard" word is 50 elements long (ie "PARIS")

  # minimum gaussian shaping:
  my $dit_shaper = $self->sine($symlen, 1/(2*$symlen));
  my $dah_shaper = $self->sine($symlen * 3, 1/(2*3*$symlen));
  # no shaping:
  #my $dit_shaper = 1;
  #my $dah_shaper = 1;

  foreach my $char (split //, $self->{msg}) {
    my $code = $PDL::Radio::Code::Morse::table->{$char};
    $code = ' ' if !defined $code;

    my $osc = sequence(0);

    foreach my $sym (split //, $code) {
      if ($sym eq '.') {
        $osc = $osc->append($self->sine($symlen, $freq) * $dit_shaper)
                   ->append($self->sine($symlen, $freq) * 0);
      } elsif ($sym eq '-') {
        $osc = $osc->append($self->sine($symlen * 3, $freq) * $dah_shaper)
                   ->append($self->sine($symlen, $freq) * 0);
      } else {
        $osc = $osc->append($self->sine($symlen * 2, $freq) * 0);
      }
    }

    $osc = $osc->append($self->sine($symlen * 2, $freq) * 0);

    $cb->($osc);
  }
}



1;
