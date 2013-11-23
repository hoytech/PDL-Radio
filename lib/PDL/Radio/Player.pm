package PDL::Radio::Player;

use common::sense;

use PDL;


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



sub play {
  my ($self, $sound) = @_;

  my $fh = $self->{fh};

  $sound->render(sub {
    my $osc = shift;
    $osc *= $self->{volume};
    print $fh ${ $osc->convert(short)->get_dataref };
  });

  return $self;
}



1;
