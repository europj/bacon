package Bacon::ForLoop;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
extends 'Bacon::Stmt';

use Bacon::Utils;

has init => (is => 'rw', isa => 'Bacon::Stmt');
has cond => (is => 'rw', isa => 'Bacon::Expr');
has incr => (is => 'rw', isa => 'Bacon::Expr');
has body => (is => 'rw', isa => 'Bacon::Stmt');

sub gen_code {
    my ($self, $depth) = @_;
    my $code = indent($depth) . "for (";

    if (defined $self->init) {
        $code .= $self->init->gen_code(0);
    }
    $code .= "; ";

    if (defined $self->cond) {
        $code .= $self->cond->gen_code(0);
    }
    $code .= "; ";

    if (defined $self->incr) {
        $code .= $self->incr->gen_code(0);
    }
    $code .= ")\n";

    $code .= $self->body->gen_code($depth);

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;