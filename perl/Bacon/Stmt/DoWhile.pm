package Bacon::DoWhile;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has cond => (is => 'ro', isa => 'Bacon::Expr');
has body => (is => 'ro', isa => 'Bacon::Stmt');

sub cost {
    my ($self, $env) = @_;
    return +'inf';
}

sub to_opencl {
    my ($self, $env, $depth) = @_;
    die "TODO: DoWhile->to_opencl";
}

__PACKAGE__->meta->make_immutable;
1;
