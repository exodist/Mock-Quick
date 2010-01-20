#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 12;

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
