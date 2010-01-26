#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

my $CLASS = 'Object::Quick';

use_ok( $CLASS );

ok( !__PACKAGE__->can( 'obj' ), "cannot obj()" );

$CLASS->import( 'obj' );

isa_ok( $CLASS->new, $CLASS );

can_ok( __PACKAGE__, 'obj' );
my $one = obj( a => 'a' );
is( $one->a, 'a', "got a" );
is( $one->b, undef, "no b" );

$one = obj({ a => 'a' });
is( $one->a, 'a', "got a" );
is( $one->b, undef, "no b" );

$one = obj( new => 'new', import => 'import', AUTOLOAD => 'autoload', PARAM => 'param' );
is( $one->new, 'new', 'new on object returns property' );
is( $one->import, 'import', 'import on object returns property' );
is( $one->AUTOLOAD, 'autoload', 'autoload on object returns property' );
is( $one->PARAM, 'param', 'param on object returns property' );


my $SELF = $one;
my $PARAMS = [ 'a', 'b' ];

my $sub = sub {
    my $self = shift;
    return is( $self, $SELF, "Got self" )
        && is_deeply( [@_], $PARAMS, "Got params" )
     ? 'sub_ran'
     : undef;
};

ok( $one->$sub( @$PARAMS ), "Sub tests passed" );

$one->sub( $sub );
is_deeply( $one->sub, $sub, "Simply stored a sub" );

$one->sub( 'a' );
is( $one->sub, "a", "Replaced" );

$one->sub( $sub, 'x' );
is_deeply( $one->sub, $sub, "Simply stored a sub" );

$one->sub( 'x', $sub );
is_deeply( $one->sub, 'x', "Simply stored a val" );

$one->sub( "MeThOd", $sub );
is_deeply( $one->sub( @$PARAMS ), "sub_ran", "VMethod" );

$one->sub( "MeThOd", undef );
is_deeply( $one->sub, undef, "VMethod cleared" );

$one->x( "MeThoD" );
is( $one->x, "MeThoD", "Can store 'method'" );

done_testing();
