package PDL::Radio::Sawtooth;

use common::sense;

use base qw(PDL::Radio::Modem);

use PDL;
use PDL::Radio;


sub new {
  my ($class, %args) = @_;

  my $self = \%args;
  bless $self, $class;

  $self->init;

  $self->{freq} //= 1000;

  return $self;
}


sub render {
  my $cb = pop @_;
  my ($self, $duration, $phase) = @_;

  $cb->($self->sawtooth($duration, $self->{freq}, $phase));
}


1;
