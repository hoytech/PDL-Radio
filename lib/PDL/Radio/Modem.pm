package PDL::Radio::Modem;

use common::sense;

use PDL;
use PDL::Radio;


sub init {
  my ($self) = @_;

  $self->{sample_rate} //= 8000;
  $self->{volume} //= 5000;
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



sub play {
  my ($self, @args) = @_;

  my $player = $self->{player} || PDL::Radio::default_player();

  $self->render(@args, sub {
    my $osc = shift;
    $player->play($osc);
  });

  return $self;
}


sub get {
  my ($self, @args) = @_;

  my $osc = sequence(0);

  $self->render(@args, sub {
    my $osc_fragment = shift;
    $osc = $osc->append($osc_fragment);
  });

  return $osc;
}


1;
