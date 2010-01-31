#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

sub capture_warn(&) {
    my ($code) = @_;
    my $warning;
    local $SIG{ __WARN__ } = sub { ($warning) = @_ };
    $code->();
    return $warning;
}

my $CLASS = 'Object::Quick';

use_ok( $CLASS );

ok( !__PACKAGE__->can( 'obj' ), "cannot obj()" );

$CLASS->import( 'obj' );

isa_ok( $CLASS->new, $CLASS );

can_ok( __PACKAGE__, 'obj' );
my $one = obj( a => 'a' );
ok( $one->can( 'a' ), "can 'a'");
is( $one->a, 'a', "got a" );
like(
    capture_warn { is( $one->b, undef, "no b" ) },
    qr/Attribute b is uninitialized/,
    "Warns of uninitialized retrieval"
);


$one = obj({ a => 'a' });
is( $one->a, 'a', "got a" );
like(
    capture_warn { is( $one->b, undef, "no b" ) },
    qr/Attribute b is uninitialized/,
    "Warns of uninitialized retrieval"
);

$one = obj( new => 'new', import => 'import', AUTOLOAD => 'autoload', PARAM => 'param' );
is( $one->new, 'new', 'new on object returns property' );
is( $one->import, 'import', 'import on object returns property' );
is( $one->AUTOLOAD, 'autoload', 'autoload on object returns property' );
is( $one->PARAM, 'param', 'param on object returns property' );

my $sub = sub { 'a' };
$one->sub( $sub );
is_deeply( $one->sub, $sub, "Simply stored a sub" );

$one->sub( 'a' );
is( $one->sub, "a", "Replaced" );

like(
    capture_warn { $one->sub( $sub, 'x' ) },
    qr/sub takes a maximum of one argument, ignoring additional arguments./,
    "Warns of too many args"
);
is_deeply( $one->sub, $sub, "Simply stored a sub" );

like(
    capture_warn { $one->sub( 'x', $sub ) },
    qr/sub takes a maximum of one argument, ignoring additional arguments./,
    "Warns of too many args"
);
is_deeply( $one->sub, 'x', "Simply stored a val" );

$one->x( "MeThoD" );
is( $one->x, "MeThoD", "Can store 'method'" );

{
    package Object::Quick::Test::__METHODS;
    use strict;
    use warnings;
    use Test::More;
    use Object::Quick qw/o vm clear/;
    my $CLASS = 'Object::Quick';

    my $one = o;
    my $SELF = \$one;
    my $PARAMS = [ 'a', 'b' ];

    my $sub = sub {
        my $self = shift;
        return (is( $self, $$SELF, "Got self" )
            && is_deeply( [@_], $PARAMS, "Got params" ))
         ? 'sub_ran'
         : undef;
    };

    can_ok( __PACKAGE__, qw/o vm clear/ );

    my $vm = vm { return 'a' };
    isa_ok( $vm, 'Object::Quick::Method' );

    ok( $one->$sub( @$PARAMS ), "Sub tests passed" );

    $one->sub( vm { $sub->(@_) });

    isa_ok( $one->{ sub }, 'Object::Quick::Method' );
    is( $one->sub( @$PARAMS ), "sub_ran", "Method" );

    $one->sub( clear );
    like(
        main::capture_warn { is( $one->sub, undef, "Method cleared" )},
        qr/Attribute sub is uninitialized/,
        "Warns of uninitialized retrieval"
    );

    $SELF = \$one;
    $one = o( sub => vm { $sub->(@_) });
    is_deeply( $one->sub( @$PARAMS ), "sub_ran", "Method" );

    $one->sub( clear );
    like(
        main::capture_warn { is( $one->sub, undef, "Method cleared" )},
        qr/Attribute sub is uninitialized/,
        "Warns of uninitialized retrieval"
    );

    $one->sub( $sub );
    is_deeply( $one->sub, $sub, "Simply stored a sub" );

    my $tmp;
    $one = o( DESTROY => vm { $tmp++ });
    ok( !$tmp, "one not destroyed" );
    $one = undef;
    ok( $tmp, "DESTROY was called" );
}

done_testing();
