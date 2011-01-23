#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Fennec::Lite;
use Mock::Quick::Method;

our $CLASS;

BEGIN {
    $CLASS = 'Mock::Quick::Class';
    use_ok( $CLASS );

    package Foo;
    1;
    package Bar;
    1;
}

tests create => sub {
    my $i = 1;
    my $obj = $CLASS->new( -with_new => 1, foo => 'bar', baz => sub { $i++ } );
    isa_ok( $obj, $CLASS );
    is( $obj->package, "$CLASS\::__ANON__\::AAAAAAAAAA", "First package" );
    can_ok( $obj->package, qw/new foo baz/ );
    isa_ok( $obj->new, $obj->package );
    is( $obj->new->baz, 1, "sub run 1" );
    is( $obj->new->baz, 2, "sub run 2" );

    $obj = $CLASS->new( -subclass => 'Foo' );
    isa_ok( $obj, $CLASS );
    is( $obj->package, "$CLASS\::__ANON__\::AAAAAAAAAB", "Second package" );
    ok( !$obj->package->can( 'new' ), "no new" );
    isa_ok( $obj->package, 'Foo' );

    $obj = $CLASS->new( -subclass => [qw/Foo Bar/] );
    isa_ok( $obj, $CLASS );
    is( $obj->package, "$CLASS\::__ANON__\::AAAAAAAAAC", "Third package" );
    isa_ok( $obj->package, 'Foo' );
    isa_ok( $obj->package, 'Bar' );
};

tests override => sub {
};

tests restore => sub {
};

tests clear => sub {
};

tests undefine => sub {
};

tests takeover => sub {
};

run_tests;
done_testing;
