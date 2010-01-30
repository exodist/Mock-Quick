#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

my $CLASS = 'Object::Quick::VMethod';

use_ok( $CLASS );

my $one = $CLASS->new( sub { 'a' });
isa_ok( $one, $CLASS );

is( $one->(), 'a', "Can run sub." );

dies_ok { $CLASS->new() } "Need argument";
dies_ok { $CLASS->new( 'a' )} "Need sub argument";

done_testing();
