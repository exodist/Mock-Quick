#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

my $CLASS;

BEGIN {
    $CLASS = 'Object::Quick';
    use_ok( $CLASS, '-all' );
}

my @METHODS = qw/ clone methods add_methods instance inherit class_methods /;

can_ok( $CLASS, @METHODS );
can_ok( __PACKAGE__, @METHODS );

ok( $CLASS->isa( $CLASS ), "isa" );
ok( $CLASS->isa( 'UNIVERSAL' ), "isa" );
ok( !$CLASS->isa( 'Borg_Cube' ), "not isa" );
ok( $CLASS->can( 'new' ), "Class can new()" );
ok( !$CLASS->can( 'Borg_Cube' ), "Class can't Borg_Cube()" );

#{{{ CLASS->method
my $one = obj( a => method { 'a' }, b => method { 'b' }, x => 'x' );
my $two = obj( c => method { 'c' }, d => method { 'd' }, y => 'y' );

######
# {{{ clone()
#
ok( my $tmp = $CLASS->clone( $one ), "clone" );
is_deeply( $tmp, $one, "copied" );
ok( $tmp != $one, "Not the same object" );
# }}}

######
# {{{ methods()
#
is_deeply(
    $CLASS->methods( $one ),
    { %Object::Quick::OBJECT_METHODS, a => $one->{ a }, b => $one->{ b } },
    "Got methods"
);
is_deeply(
    $CLASS->methods( $two ),
    { %Object::Quick::OBJECT_METHODS, c => $two->{ c }, d => $two->{ d } },
    "Got methods"
);
# }}}

######
# {{{ add_methods
#
$tmp = obj;
$CLASS->add_methods( $tmp, x => sub { 'x' }, y => method { 'y' });
isa_ok( $tmp->{ x }, 'Object::Quick::Method' );
isa_ok( $tmp->{ y }, 'Object::Quick::Method' );
is( $tmp->x, 'x', "Correct value for x" );
is( $tmp->y, 'y', "Correct value for y");
# }}}

######
# {{{ instance
#
$tmp = $CLASS->instance( $one );
is_deeply(
    $CLASS->methods( $tmp ),
    $CLASS->methods( $one ),
    "Same methods"
);
ok( $one->x, "original has attribute" );
ok( !$tmp->x, "instance did not copy attributes" );
# }}}

######
# {{{ inherit
#
$tmp = obj;
$CLASS->inherit( $tmp, $one );
is_deeply(
    $CLASS->methods( $tmp ),
    $CLASS->methods( $one ),
    "Same methods"
);
ok( $one->x, "original has attribute" );
ok( !$tmp->x, "new did not copy attributes" );
# }}}

######
# {{{ class_methods
#
my $cmo = clone( $one );
$CLASS->class_methods( $cmo );
isa_ok( $cmo->{ $_ }, 'Object::Quick::Method' ) for @METHODS;

#Individual ones are tested in the 'Imported' section.

#}}}
#}}}

#{{{ Imported
$one = obj( a => method { 'a' }, b => method { 'b' }, x => 'x' );
$two = obj( c => method { 'c' }, d => method { 'd' }, y => 'y' );

######
# {{{ clone()
#
ok( $tmp = clone( $one ), "clone" );
is_deeply( $tmp, $one, "copied" );
ok( $tmp != $one, "Not the same object" );
# }}}

######
# {{{ methods()
#
is_deeply(
    methods( $one ),
    { %Object::Quick::OBJECT_METHODS, a => $one->{ a }, b => $one->{ b } },
    "Got methods"
);
is_deeply(
    methods( $two ),
    { %Object::Quick::OBJECT_METHODS, c => $two->{ c }, d => $two->{ d } },
    "Got methods"
);
# }}}

######
# {{{ add_methods
#
$tmp = obj;
add_methods( $tmp, x => sub { 'x' }, y => method { 'y' });
isa_ok( $tmp->{ x }, 'Object::Quick::Method' );
isa_ok( $tmp->{ y }, 'Object::Quick::Method' );
is( $tmp->x, 'x', "Correct value for x" );
is( $tmp->y, 'y', "Correct value for y");
# }}}

######
# {{{ instance
#
$tmp = instance( $one );
is_deeply(
    methods( $tmp ),
    methods( $one ),
    "Same methods"
);
ok( $one->x, "original has attribute" );
ok( !$tmp->x, "instance did not copy attributes" );
# }}}

######
# {{{ inherit
#
$tmp = obj;
inherit( $tmp, $one );
is_deeply(
    methods( $tmp ),
    methods( $one ),
    "Same methods"
);
ok( $one->x, "original has attribute" );
ok( !$tmp->x, "new did not copy attributes" );
# }}}

######
# {{{ class_methods
#
$cmo = clone( $one );
class_methods( $cmo );
isa_ok( $cmo->{ $_ }, 'Object::Quick::Method' ) for @METHODS;

######
# {{{ clone()
#
ok( $tmp = $cmo->clone, "clone" );
is_deeply( $tmp, $cmo, "copied" );
ok( $tmp != $cmo, "Not the same object" );
# }}}

######
# {{{ methods()
#
is_deeply(
    $cmo->methods,
    {
        map { $_ => $cmo->{ $_ } || 'NOT REAL' } qw/ a b clone methods
            add_methods instance inherit class_methods DESTROY isa can new
            VERSION DOES/
    },
    "Got methods"
);
# }}}

######
# {{{ add_methods
#
$tmp = obj;
class_methods( $tmp );
$tmp->add_methods( x => sub { 'x' }, y => method { 'y' });
isa_ok( $tmp->{ x }, 'Object::Quick::Method' );
isa_ok( $tmp->{ y }, 'Object::Quick::Method' );
is( $tmp->x, 'x', "Correct value for x" );
is( $tmp->y, 'y', "Correct value for y");
# }}}

######
# {{{ instance
#
$tmp = $cmo->instance;
is_deeply(
    methods( $tmp ),
    methods( $cmo ),
    "Same methods"
);
ok( $cmo->x, "original has attribute" );
ok( !$tmp->x, "instance did not copy attributes" );
# }}}

######
# {{{ inherit
#
$tmp = obj;
class_methods( $tmp );
delete $cmo->{ $_ } for @METHODS;
$tmp->inherit( $cmo );
delete $tmp->{ $_ } for @METHODS;
is_deeply(
    methods( $tmp ),
    methods( $cmo ),
    "Same methods"
);
ok( $cmo->x, "original has attribute" );
ok( !$tmp->x, "new did not copy attributes" );
# }}}
# }}}
#}}}

done_testing();
