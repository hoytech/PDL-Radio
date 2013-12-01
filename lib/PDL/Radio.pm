package PDL::Radio;

use common::sense;

our $VERSION = '0.001';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(PI);

sub PI () { 3.14159265358979 }


use PDL::Radio::Player;



our $DEFAULT_PLAYER;

sub default_player {
  $DEFAULT_PLAYER ||= PDL::Radio::Player->new;
  return $DEFAULT_PLAYER;
}


#use PDL::Graphics::PGPLOT; dev('/XSERVE'); line($osc);
#use PDL::Graphics::Gnuplot; gplot($osc, { terminal => 'x11' }); sleep 100000;


1;



__END__


=encoding utf-8

=head1 NAME

PDL::Radio - Amateur radio system built on PDL

=head1 SYNOPSIS

    ## Play 1000 Hz sine wave for 5 seconds:
    PDL::Radio->new->play("sine", 5, 1000);

    ## Play .5 seconds of a sine wave, phase shift 180 degrees, play another .5:
    PDL::Radio->new->play("sine", .5, 1000)
                   ->play("sine", .5, 1000, PI);

    ## Plot 5 periods of a sawtooth wave:
    PDL::Radio->new->plot("sawtooth", 5, 1);

    ## Play PSK-31 encoded message
    PDL::Radio->new->play("psk", 1000, "hello world!");

=head1 DESCRIPTION

This is a work-in-progress library for generating sound data and playing it through L<Pulse Audio|http://www.freedesktop.org/wiki/Software/PulseAudio/>. Pulse Audio makes redirecting the audio output to programs like L<fldigi|http://www.w1hkj.com/Fldigi.html> really easy.

=head1 SEE ALSO

L<The PDL::Radio github repo|https://github.com/hoytech/PDL-Radio>

L<PDL::Audio> is very similar to this module except that it interfaces to sndlib where this module interfaces to pulseaudio. L<PDL::Audio> is a pain to setup and I couldn't figure out how to send data to fldigi. Also, L<Pulse::Audio> doesn't seem to be on CPAN anymore?

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012-2013 Doug Hoyte.

This module is licensed under the same terms as perl itself.

=cut
