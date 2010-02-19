#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Object::Quick qw/o/;

{
    package Exception::Fail;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $new = bless( { }, $class );
        return $new;
    }

    sub new_with_init {
        my $class = shift;
        my $new = bless( { }, $class );
        $new->init;
        return $new;
    }

    sub init {
        my $self = shift;
        for my $item ( qw/a b c/ ) {
            die( "No x: '$item'" ) unless 0;
        }
    }
}

my $one;

dies_ok {
    $one = Exception::Fail->new_with_init( o() )
} "new_with_init - object-quick";

dies_ok {
    $one = Exception::Fail->new( o() )->init
} "init is called in chain - object-quick";

done_testing();
