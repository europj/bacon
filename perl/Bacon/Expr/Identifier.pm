package Bacon::Expr::Identifier;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Expr;
extends 'Bacon::Expr';

has name => (is => 'ro', isa => 'Str');

use Carp;
use Data::Dumper;

use Bacon::Utils;
use Bacon::MagicVars;

sub static_eval {
    my ($self, $env) = @_;
    return $env->value($self->name);
}

sub to_ocl {
    my ($self, $env) = @_;
    confess "Undefined \$env" unless defined $env;

    my $name = $self->name;

    # Handle "magic" variables.
    if ($name =~ /^\$/) {
        confess "Invalid magic variable: $name"
            unless Bacon::MagicVars::magic_var_exists($name);
        $name =~ s/^\$/_bacon__S/;
        return $name;
    }

    if (defined $env->value($name)) {
        return $self->static_eval($env);
    }
    
    return $name;
}

sub to_cpp {
    my ($self, undef) = @_;
    my $name = $self->name;
    confess "Can't use magic variables in C++" if ($name =~ /^\$/);
    return $name;
}

__PACKAGE__->meta->make_immutable;
1;
