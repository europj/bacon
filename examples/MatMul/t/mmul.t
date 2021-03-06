#!/usr/bin/perl
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use FindBin qw($Bin);
chdir "$Bin/..";

my $ldpath = "";
if (defined $ENV{LD_LIBRARY_PATH}) {
    $ldpath = ":" . ($ENV{LD_LIBRARY_PATH} || "");
}

$ENV{LD_LIBRARY_PATH} = "../../lib" . $ldpath;

use Test::Simple tests => 4;
use Bacon::Test;

my $tmp = "t/out-$$.dat";

system("./mmul -a t/aa.dat -b t/id4.dat -o $tmp");
files_eq($tmp, "t/aa.dat", "MatMul - identity matrix");
unlink($tmp);

system("./mmul -p -a t/aa.dat -b t/id4.dat -o $tmp");
files_eq($tmp, "t/aa.dat", "MatMul - identity matrix, cpu");
unlink($tmp);

system("./mmul -a t/aa.dat -b t/bb.dat -o $tmp");
files_eq($tmp, "t/out.dat", "MatMul - arbitrary matrix");
unlink($tmp);

my $result = `./mmul -c -n 1024`;
chomp $result;
ok($result eq "Random test succeeded.", "MatMul - large matrix");
