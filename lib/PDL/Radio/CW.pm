package PDL::Radio::CW;

use common::sense;

use base qw(PDL::Radio::Modem);

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
  $self->{shape} //= 'hanning';
  $self->{risetime} //= 4;

  return $self;
}



sub render {
  my ($self, $msg, $cb) = @_;

  $msg = uc $msg;

  my $freq = $self->{freq};

  my $symlen = 60 / ($self->{wpm} * 50); ## A "standard" word is 50 elements long (ie "PARIS")

  my ($dit_shaper, $dah_shaper);

  if ($self->{shape} eq 'hanning') {
    my ($dit_len) = $self->sine($symlen, $freq)->dims;
    my $dah_len = $dit_len * 3;

    my $shape_len = $self->{risetime} * $self->{sample_rate} / 1000;
    $shape_len = $dit_len/2 if $shape_len > $dit_len/2;

    my $edge = (1 - cos(PI * sequence($shape_len) / $shape_len)) * 0.5;

    $dit_shaper = $edge->append(ones($dit_len - $shape_len*2))->append($edge->slice("-1:0:-1"));
    $dah_shaper = $edge->append(ones($dah_len - $shape_len*2))->append($edge->slice("-1:0:-1"));
  } elsif ($self->{shape} eq 'min') {
    $dit_shaper = $self->sine($symlen, 1/(2*$symlen));
    $dah_shaper = $self->sine($symlen * 3, 1/(2*3*$symlen));
  } elsif ($self->{shape} eq 'hard') {
    $dit_shaper = 1;
    $dah_shaper = 1;
  } else {
    die "unknown keying shape: $self->{shape}";
  }

  foreach my $char (split //, $msg) {
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
