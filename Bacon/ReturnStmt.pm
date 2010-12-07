package Bacon::ReturnStmt;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has expr => (is => 'rw', isa => 'Maybe[Bacon::Expr]');

sub gen_code {
    my ($self, $depth) = @_;
    if (!defined $self->expr) {
        return indent($depth) . "return;\n";
    }
    else {
        return indent($depth) . "return "
            . $self->expr->gen_code(0) . ";\n";
    }
}

__PACKAGE__->meta->make_immutable;
1;