package Bacon::Expr::BinaryOp;
use warnings FATAL => 'all';
use strict;
use 5.10.0;

use Moose;
use namespace::autoclean;
use Carp;

use Bacon::Expr;
use Exporter;
extends 'Bacon::Expr', 'Exporter';

our @EXPORT_OK = qw(mkop);

use Data::Dumper;
use List::MoreUtils qw(any);
use Bacon::Utils;

has name => (is => 'ro', isa => 'Str', required => 1);
has arg0 => (is => 'ro', isa => 'Bacon::Expr', required => 1);
has arg1 => (is => 'ro', isa => 'Bacon::Expr', required => 1);

sub mkop {
    my ($op, $aa, $bb) = @_;
    return __PACKAGE__->new3($op, $aa, $bb);
}

sub new3 {
    my ($class, $op, $aa, $bb) = @_;
    return $class->new(name => $op, arg0 => $aa, arg1 => $bb);
}

sub kids {
    my ($self) = @_;
    return ($self->arg0, $self->arg1);
}

sub is_cond {
    my ($self) = @_;
    my @cond_ops = qw(< > <= >= ==);

    for my $op (@cond_ops) {
        return 1 if ($op eq $self->name);
    }

    return 0;
}

sub is_const_cond {
    my ($self, $env, $var) = @_;
    confess "No var specified" unless defined $var;

    return 0 unless $self->is_cond;

    unless ($self->arg0->is_const($env) || $self->arg1->is_const($env)) {
        return 0;
    }

    unless (($self->arg0->isa('Bacon::Expr::Identifier') && $self->arg0->name eq $var) 
         || ($self->arg1->isa('Bacon::Expr::Identifier') && $self->arg1->name eq $var)) {
        return 0;
    }

    return 1;
}

sub normalize_const_cond {
    my ($self, $env, $var) = @_;
    die "That's not a constant condition" unless $self->is_const_cond($env, $var);

    my $op = $self->name;
    my $num;

    if ($self->arg0->is_const($env)) {
        $num = $self->arg0->static_eval($env);
        # Flip the conditional 
        $op =~ tr/<>/></;
    }
    else {
        $num = $self->arg1->static_eval($env);
    }

    if ($op =~ /=/) {
        if ($num > 0) {
            $op =~ s/=//;
            $num += 1;
        }
        else {
            die "TODO: Fix normalize const cond";
        }
    }

    return ($op, $num);
}

sub op_mutates {
    my ($self) = @_;
    my @mutating_ops = qw(= += -= *= /= %= &= ^= |= >>= <<=);
    for my $op (@mutating_ops) {
        return 1 if ($op eq $self->name);
    }
    return 0;
}

sub mutates_variable {
    my ($self, $var) = @_;

    if (any { $_->mutates_variable($var) } $self->kids) {
        return 1;
    }

    unless ($self->arg0->isa('Bacon::Expr::Identifier') && 
            $self->arg0->name eq $var) {
        return 0;
    }

    return $self->op_mutates;
}

sub normalize_increment {
    my ($self, $env, $var) = @_;

    unless ($self->arg0->isa('Bacon::Expr::Identifier') && 
            $self->arg0->name eq $var) {
        return undef;
    }

    my $value = $self->arg1->try_static_eval($env);

    return undef unless defined $value;

    return +$value if ($self->name eq '+=');
    return -$value if ($self->name eq '-=');

    return undef;
}

sub writes_to_array {
    my ($self, $name) = @_;
    return $self->op_mutates
        && $self->arg0->isa('Bacon::Expr::ArrayIndex')
        && $self->arg0->name eq $name;
}

sub static_eval {
    my ($self, $env) = @_;
    my $op = $self->name;
    my $aa = $self->arg0->static_eval($env);
    my $bb = $self->arg1->static_eval($env);
    return 0 + eval "$aa $op $bb";
}

sub to_ocl {
    my ($self, $env) = @_;

    if ($self->op_mutates && 
            $self->arg0->isa('Bacon::Expr::ArrayIndex')) {
        my $var = $env->lookup($self->arg0->name)
           or confess("No variable named " . $self->arg0->name);
        if ($var->type_isa("Bacon::Type::Image")) {
            return $var->type->image_write_to_ocl(
                $var, $env, @{$self->arg0->dims}, $self->arg1);
        }
    }

    my $val = $self->try_static_eval($env);
    if (defined $val) {
        return "$val";
    }

    return "("
        . $self->arg0->to_ocl($env)
        . $self->name 
        . $self->arg1->to_ocl($env) 
        . ")";
}

sub to_cpp {
    my ($self, $fun) = @_;
    return "("
        . $self->arg0->to_cpp($fun)
        . $self->name 
        . $self->arg1->to_cpp($fun) 
        . ")";
}

__PACKAGE__->meta->make_immutable;
1;
