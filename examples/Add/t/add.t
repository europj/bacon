#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use FindBin qw($Bin);
chdir "$Bin/..";

use Test::Simple tests => 1;
use Bacon::Test;

my $tmp = "t/out-$$.dat";

system("./add -a t/aa.dat -b t/bb.dat -o $tmp");
files_eq($tmp, "t/out.dat", "Array2D add");
unlink($tmp);
