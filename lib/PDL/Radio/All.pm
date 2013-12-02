package PDL::Radio::All;

use PDL;
use PDL::Radio;
use PDL::Radio::CW;
use PDL::Radio::RTTY;
use PDL::Radio::PSK;
use PDL::Radio::Sine;
use PDL::Radio::Square;
use PDL::Radio::Sawtooth;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(PI plot);


sub plot {
  my $osc = shift;

  require PDL::Graphics::Gnuplot;
  PDL::Graphics::Gnuplot::gplot($osc, { terminal => 'x11' });

  sleep 100000;
}


1;

__END__

=pod

Just a convenience package to load everything for easier command-line experimentation

=cut
