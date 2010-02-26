#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Object::Quick '-all';

my $CLASS = 'Object::Quick';

{
    package Base::OQTest;
    use strict;
    use warnings;

    sub a { 'a' }
    sub b { 'b' }
    sub c { 'c' }

    package Base::OQTest::SubClass;
    use strict;
    use warnings;

    use base 'Base::OQTest';

    sub c { 'new c' }
    sub d { 'd' }

    package Base::OQTest2;
    use strict;
    use warnings;

    sub g { 'g' }
    sub h { 'h' }
}

my $one;

TODO: {
    local $TODO = "Not Implemented";

    $one = obj()
        unless lives_and { $one = $CLASS->new_with_base( 'Base::OQTest::SubClass', { x => 'x', a => 'override' })} "new_with_base";
    isa_ok( $one->$_, 'Object::Quick::Method' ) for qw/a b c d x/;
    is( $one->a, 'override', "override method" );
    is( $one->b, 'b', "used baseclass-baseclass method" );
    is( $one->c, 'new c', "used baseclass overriden method" );
    is( $one->d, 'd', "used baseclass method" );
    isa_ok( $one, 'Base::OQTest::SubClass', 'Base::OQTest' );
    $one->b( clear );
    ok( !$one->b );

    $one = obj()
        unless lives_and { $one = obj_with_base( 'Base::OQTest::SubClass', { x => 'x', a => 'override' })} "obj_with_base";
    isa_ok( $one->$_, 'Object::Quick::Method' ) for qw/a b c d x/;
    isa_ok( $one, 'Base::OQTest::SubClass', 'Base::OQTest' );

    $one = obj();
    lives_and { $CLASS->inherit( $one, 'Base::OQTest::SubClass', 'a' .. 'd' )} "CLASS->inherit";
    isa_ok( $one->$_, 'Object::Quick::Method' ) for qw/a b c d/;
    is( $one->a, 'a', "inherited method" );
    ok( !$one->isa( 'Base::OQTest::SubClass' ));
    ok( !$one->isa( 'Base::OQTest' ));

    $one = obj();
    lives_and { $CLASS->inherit( $one, 'Base::OQTest::SubClass' )} "CLASS->inherit";
    isa_ok( $one->$_, 'Object::Quick::Method' ) for qw/a b c d/;

    $one = obj();
    lives_and { $CLASS->base( $one, 'Base::OQTest::SubClass', 'a' .. 'c' )} "CLASS->base";
    isa_ok( $one->$_, 'Object::Quick::Method' ) for qw/a b c/;
    is( $one->a, 'a', "inherited method" );
    isa_ok( $one, 'Base::OQTest::SubClass', 'Base::OQTest' );

    lives_and { $one = obj( inherit( 'Base::OQTest2', qw/g h/), base( 'Base::OQTest::SubClass' ))} "base() and obj() in constructor";
    isa_ok( $one->$_, 'Object::Quick::Method' ) for qw/a b c d g h/;

    isa_ok( $one, 'Base::OQTest::SubClass', 'Base::OQTest' );

    ok( !$one->isa( 'Base::OQTest2' ), 'Object not a Base::OQTest2' );

    $one = obj();
    lives_and { inherit( $one, 'Base::OQTest2', qw/a b/ )} "inherit imported";
    isa_ok( $one->$_, 'Object::Quick::Method' ) for qw/a b/;
    ok( !$one->isa( 'Base::OQTest2' ), 'Object not a Base::OQTest2' );

    $one = obj();
    lives_and { base( $one, 'Base::OQTest2', qw/a b/ )} "base imported";
    isa_ok( $one->$_, 'Object::Quick::Method' ) for qw/a b/;
    isa_ok( $one, 'Base::OQTest2' );
}

done_testing();
