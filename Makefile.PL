use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'PDL::Sound',
    VERSION_FROM => 'lib/PDL/Sound.pm',
    PREREQ_PM => {
      'common::sense' => 0,
      'PDL' => 0,
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'perldoc -uT lib/PDL/Sound.pm > README.pod; pod2text README.pod > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/PDL-Sound.git',
            bugtracker => 'https://github.com/hoytech/PDL-Sound/issues',
        },
    };
}

WriteMakefile(%args);
