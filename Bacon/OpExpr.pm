package Bacon::OpExpr;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

use Bacon::Utils;

has name => (is => 'ro', isa => 'Str', required => 1);
has args => (is => 'ro', isa => 'ArrayRef[Bacon::Expr]');
has post => (is => 'rw', isa => 'Bool', default => 0);

sub new_args {
    my ($class, $op, @args) = @_;
    my $self = $class->new_from_token(name => $op, args => [@args]);
    return $self;
}

sub set_post {
    my ($self) = @_;
    $self->post(1);
    return $self;
}

sub gen_code {
    my ($self, $depth) = @_;
    my $argc = scalar @{$self->args};

    return $self->gen_funcall($depth) if $self->name eq '(';
    return $self->gen_arryref($depth) if $self->name eq '[';
    return $self->gen_code1($depth) if $argc == 1;
    return $self->gen_code2($depth) if $argc == 2;
    return $self->gen_code3($depth) if $argc == 3;
    die "Unknown op: " . $self->name . ", $argc args.";
}

sub gen_funcall {
    my ($self, $depth) = @_;
    my ($what, @args) = @{$self->args};
    my @ac = map { $_->gen_code(0) } @args;
    return indent($depth) . $what->gen_code(0)
        . '(' . join(', ', @ac) . ')';
}

sub gen_arryref {
    my ($self, $depth) = @_;
    my ($what, @args) = @{$self->args};
    my @ac = map { $_->gen_code(0) } @args;
    return indent($depth) . $what->gen_code(0) 
        . '[' . join(', ', @ac) . ']';
}

sub gen_code1 {
    my ($self, $depth) = @_;
    my @args = @{$self->args};
    if ($self->post) {
        return indent($depth) . "(" . $args[0]->gen_code(0) 
            . $self->name . ")";
    }
    else {
        return indent($depth) . "(" . $self->name 
            . $args[0]->gen_code(0) . ")";
    }
}

sub gen_code2 {
    my ($self, $depth) = @_;
    my @args = @{$self->args};
    return indent($depth) . "(" . $args[0]->gen_code(0)
        . $self->name . $args[1]->gen_code(0) . ")";
}

sub gen_code3 {
    my ($self, $depth) = @_;
    my @args = @{$self->args};
    return indent($depth) . "(" . $args[0]->gen_code(0)
        . $self->name . $args[1]->gen_code(0) . ")";
}

__PACKAGE__->meta->make_immutable;
1;