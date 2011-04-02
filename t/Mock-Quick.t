#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Fennec::Lite;

BEGIN {
    require_ok( 'Mock::Quick' );
    Mock::Quick->import();
    can_ok( __PACKAGE__, qw/ qobj qclass qtakeover qclear qmeth /);

    package Foo;
}

tests object => sub {
    is( qclear(), \$Mock::Quick::Util::CLEAR, "clear returns the clear reference" );

    my $one = qobj( foo => 'bar' );
    isa_ok( $one, 'Mock::Quick::Object' );
    is( $one->foo, 'bar', "created properly" );

    my $two = qmeth { 'vm' };
    isa_ok( $two, 'Mock::Quick::Method' );
    is( $two->(), "vm", "virtual method" );

    my $three = qobj( foo => qmeth { 'bar' } );
    is( $three->foo, 'bar', "ran virtual method" );
    $three->foo( qclear() );
    ok( !$three->foo, "cleared" );

    my $four = qstrict( foo => qmeth { 'bar' } );

    is( $four->foo, 'bar', "ran virtual method" );

    throws_ok { $four->baz }
        qr/Can't locate object method "baz" in this instance/,
        "Strict mode";

    $four->foo( qclear() );
    throws_ok { $four->foo }
        qr/Can't locate object method "foo" in this instance/,
        "Strict mode";

    my ( $five, $fcontrol ) = qobj( foo => 'bar' );
    isa_ok( $five, 'Mock::Quick::Object' );
    isa_ok( $fcontrol, 'Mock::Quick::Object::Control' );
    ok( !$fcontrol->strict, "not strict" );

    my ( $six, $scontrol ) = qstrict( foo => 'bar' );
    isa_ok( $six, 'Mock::Quick::Object' );
    isa_ok( $scontrol, 'Mock::Quick::Object::Control' );
    ok( $scontrol->strict, "strict" );
};

tests class => sub {
    my $one = qclass( foo => 'bar' );
    isa_ok( $one, 'Mock::Quick::Class' );
    can_ok( $one->package, 'foo' );

    my $two = qtakeover( 'Foo' );
    isa_ok( $two, 'Mock::Quick::Class' );
    is( $two->package, 'Foo', "took over Foo" );

    my $three = qimplement( 'Foox', -with_new => 1 );
    lives_ok { require Foox; 1 } "Did not try to load Foox";
    can_ok( 'Foox', 'new' );
    $three->undefine();
    throws_ok { require Foox; 1 } qr/Can't locate Foox\.pm/,  "try to load Foox";
};

run_tests;
done_testing;
