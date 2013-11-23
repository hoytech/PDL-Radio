package PDL::Radio::Baudot;

use common::sense;

## Tables adapted from fldigi

our $letters = [
        "\0",   "E",    "\n",   "A",    " ",    "S",    "I",    "U",
        "\r",   "D",    "R",    "J",    "N",    "F",    "C",    "K",
        "T",    "Z",    "L",    "W",    "H",    "Y",    "P",    "Q",
        "O",    "B",    "G",    "FIGS", "M",    "X",    "V",    "LTRS",
];

# U.S. version of the figures case.

our $figures = [
        "\0",   "3",    "\n",   "-",    " ",    "\a",   "8",    "7",
        "\r",   "\$",   "4",    "'",    ",",    "!",    ":",    "(",
        "5",    "\"",   ")",    "2",    "#",    "6",    "0",    "1",
        "9",    "?",    "&",    "FIGS", ".",    "/",    ";",    "LTRS",
];



our $letters_lookup = {};
our $figures_lookup = {};

for my $i (0..31) {
  $letters_lookup->{$letters->[$i]} = $i;
  $figures_lookup->{$figures->[$i]} = $i;
}


1;
