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
    package Baz;
    sub foo { 'foo' }
    sub bar { 'bar' }
    sub baz { 'baz' }
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

    $obj = $CLASS->new( -with_new => 1, -attributes => [qw/a b c/] );
    can_ok( $obj->package, qw/a b c/ );
    my $one = $obj->package->new;
    $one->a( 'a' );
    is( $one->a, 'a', "get/set" );
};

tests override => sub {
    my $obj = $CLASS->new( foo => 'bar' );
    is ( $obj->package->foo, 'bar', "original value" );
    $obj->override( 'foo', sub { 'baz' });
    is( $obj->package->foo, 'baz', "overriden" );
    $obj->restore( 'foo' );
    is( $obj->package->foo, 'bar', "original value" );

    $obj->override( 'bar', sub { 'xxx' });
    is( $obj->package->bar, 'xxx', "overriden" );
    $obj->restore( 'bar' );
    ok( !$obj->package->can( 'bar' ), "original value is nill" );
};

tests undefine => sub {
    my $obj = $CLASS->new( foo => 'bar' );
    can_ok( $obj->package, 'foo' );
    $obj->undefine;
    no strict 'refs';
    ok( !keys %{$obj->package . '::'}, "anon package undefined" );
    ok( !$obj->package->can( 'foo' ), "no more foo method" );
};

tests takeover => sub {
    my $obj = $CLASS->takeover( 'Baz' );
    is( Baz->foo, 'foo', 'original' );
    $obj->override( 'foo', sub { 'new foo' });
    is( Baz->foo, 'new foo', "override" );
    $obj->restore( 'foo' );
    is( Baz->foo, 'foo', 'original' );

    $obj = $CLASS->takeover( 'Baz' );
    is( Baz->foo, 'foo', 'original' );
    $obj->override( 'foo', sub { 'new foo' });
    is( Baz->foo, 'new foo', "override" );
    $obj = undef;
    is( Baz->foo, 'foo', 'original' );
};

run_tests;
done_testing;
