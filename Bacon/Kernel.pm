package Bacon::Kernel;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;

use Data::Dumper;

use Bacon::Function;
extends 'Bacon::Function';

has dist => (is => 'rw', isa => 'Maybe[ArrayRef[Bacon::Expr]]');

use Bacon::Utils;

sub new4 {
    my ($class, $fun, $rtype, $dist, $body) = @_;
    assert_type($body, 'Bacon::CodeBlock');
    my $self = $class->new(
        file => $fun->file, line => $fun->line,
        name => $fun->name, args => $fun->args,
        retv => $rtype, body => $body, dist => $dist
    );
    return $self;
}

sub find_return_var {
    my ($self) = @_;
    return undef unless (defined $self->retv);

    my $name = $self->name;
    my @rets = grep { $_->isa('Bacon::ReturnStmt') } $self->subnodes;
    
    if (scalar @rets == 0 || !defined $rets[0]->expr) {
        die "Kernel '$name' has return type but doesn't return a value.\n";
    }

    my $var = $rets[0]->expr;

    for my $stmt (@rets) {
        my $expr = $stmt->expr;
        
        die "Mismatched return type in kernel '$name' at " . $stmt->source
            unless (defined $expr);

        die "Kernel '$name' must return exactly one variable"
            unless ($expr->name eq $var->name);
    }

    return $var->name;
}

sub init_magic_variables {
    my ($self) = @_;
    my @vars = grep { 
        $_->isa('Bacon::Identifier') && $_->name =~ /^\$/
    } $self->subnodes;

    my %seen = ();

    for my $var (@vars) {
        $seen{$var->name} = 1;
    }

    my $code = '';

    if ($seen{'$x'}) {
        $code .= indent(1);
        $code .= "int _bacon__Sx = get_global_id(0);\n";
    }
    
    if ($seen{'$y'}) {
        $code .= indent(1);
        $code .= "int _bacon__Sy = get_global_id(1);\n";
    }
    
    if ($seen{'$z'}) {
        $code .= indent(1);
        $code .= "int _bacon__Sz = get_global_id(2);\n";
    }

    return $code;
}

sub to_opencl {
    my ($self, $pgm) = @_;
    assert_type($pgm, "Bacon::Program");

    my $code = "/* Kernel: " . $self->name . 
               " " . $self->source . " */\n";

    my @dims = map { $_->to_opencl($self, 0) } @{$self->dist};
    $code .= "kernel void\n";
    $code .= "/* returns: " . $self->retv . "\n";
    $code .= " * distrib: ";
    $code .= " [" . join(', ', @dims) . "]\n";
    $code .= " */\n";

    if ($self->retv ne 'void') {
        my $vname = $self->find_return_var;
        my $var = $self->vtab->{$vname};
        my $arg = $var->to_funarg;
        $self->vtab->{$vname} = $arg;
    }
    
    my @args = $self->expanded_args;
    $code .= $self->name . "(";
    $code .= join(', ', map {$_->to_opencl($self, 0)} @args);
    $code .= ")\n";

    $code .= "{\n";

    $code .= $self->init_magic_variables;
    
    my @vars = $self->expanded_vars;
    for my $var (@vars) {
        $code .= $var->decl_to_opencl($self, 1);
    }

    $code .= $self->body->contents_to_opencl($self, 0);

    $code .= "}\n\n";

    return $code;
}

__PACKAGE__->meta->make_immutable;
1;
