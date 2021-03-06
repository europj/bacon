package Bacon::Stmt::VarDecl;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Bacon::Stmt;
use Bacon::Variable;
extends 'Bacon::Stmt';

has name => (is => 'ro', isa => 'Str', required => 1);
has dims => (is => 'ro', isa => 'Maybe[ArrayRef[Bacon::Expr]]');
has init => (is => 'ro', isa => 'Maybe[Bacon::Expr]');

has var  => (is => 'ro', isa => 'Bacon::Variable', required => 1);

use Data::Dumper;
use List::Util qw(reduce);
use Carp;

use Bacon::Utils;
use Bacon::Expr::BinaryOp qw(mkop);

sub kids {
    my ($self) = @_;
    my @kids = ();
    push @kids, @{$self->dims} if (defined $self->dims);
    push @kids, $self->init if (defined $self->init);
    return @kids;
}

sub new_dimen {
    my ($self, $name, $val_expr) = @_;
    return ref($self)->new(
        file => $self->file, line => $self->line,
        name => $name, type => 'uint', init => $val_expr);
}

sub to_setup_cc {
    my ($self, $fun) = @_;
    return $self->to_cpp_decl($fun);
}

sub to_cpp_decl {
    my ($self, $fun) = @_;
    my $code = '';
    my $env = $fun->env;
    my $var = $env->lookup($self->name);

    $code .= $var->type->to_cpp . ' ';
    $code .= $self->name;

    if ($self->dims) {
        my @dims = map { $_->to_cpp($fun) } @{$self->dims};
        $code .= '(';
        $code .= join(', ', @dims);
        $code .= ')';
    }

    if (defined $self->init) {
        $code .= ' = ';
        $code .= $self->init->to_cpp($fun);
    }

    $code .= ';';
    return $code;
}

sub decl_to_opencl {
    my ($self, $env, $depth) = @_;
    assert_type($env, 'Bacon::Environment');
    return '' if $self->var->is_const;

    if ($self->var->type->isa("Bacon::Type::Array")) {
        return $self->array_to_opencl($env, $depth);
    }

    my $code = indent($depth) . $self->var->type->to_ocl 
        . ' ' . $self->name;

    if (defined $self->dims) {
        my @dims = @{$self->dims};
        unless (scalar @dims == 1) {
            die "Simple array can't have multiple dimensions at " . $self->source; 
        }

        $code .= '[' . $dims[0]->to_ocl($env) . ']';
    }

    $code .= ";\n";
    return $code;
}

sub to_opencl {
    my ($self, $env, $depth) = @_;
    return '' if $self->var->is_const;

    my $code = '';

    if (defined $self->init) {
        $code .= indent($depth) . $self->name;
        $code .= " = " . $self->init->to_ocl($env) . ";\n";
    }    

    return $code;
}

sub array_to_opencl {
    my ($self, $env, $depth) = @_;
    my $var  = $env->lookup($self->name);
    my $type = $var->type;
    my $name = $self->name;
    my $code = '';

    my $size = reduce { $a * $b } (map { $_->static_eval($env) } @{$self->dims});

    $code .= indent($depth) . $var->type->to_ocl . " " . $name . ";\n";
    
    for (my $ii = 0; $ii < scalar @{$type->dims}; ++$ii) {
        my $dim = $type->dims->[$ii];
        my $val = $self->dims->[$ii]->to_ocl($env);
        $code .= indent(1) . "$name.$dim = $val;\n";
    }    

    my $ptr_type = $var->type->subtype->to_ocl;
    $code .= indent($depth) . $ptr_type . ' ' . $name . "__data[$size];\n";
    $code .= indent($depth) . "$name.data = $name" . "__data;\n";

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
