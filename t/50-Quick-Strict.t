#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

my $CLASS = 'Object::Quick::Strict';

use_ok( $CLASS );

ok( !__PACKAGE__->can( 'obj' ), "cannot obj()" );

$CLASS->import( 'obj' );

isa_ok( $CLASS->new, $CLASS );

can_ok( __PACKAGE__, 'obj' );
my $one = obj( a => 'a' );
ok( $one->can( 'a' ), "can 'a'");
is( $one->a, 'a', "got a" );
dies_ok { $one->b } "Cannot use uninitialized method";
lives_ok { $one->b( 'b' ) } "Initialize method";
lives_ok { $one->b } "works now";

ok( ! $one->can(), "No args" );
ok( ! Object::Quick::Strict->can( 'xxx' ), "Not a ref" );

done_testing();
