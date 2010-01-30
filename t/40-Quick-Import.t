#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

my $CLASS = 'Object::Quick';
use_ok( $CLASS );

my @CLASS_METHODS = qw/ clone methods add_methods instance inherit class_methods /;
my @DEFAULTS = qw/ obj method clear /;

#{{{ imports
{
    package main::A;
    use Object::Quick;

    package main::B;
    use Object::Quick '-obj';

    package main::C;
    use Object::Quick '-class';

    package main::D;
    use Object::Quick '-all';

    package main::E;
    use Object::Quick 'o';

    package main::F;
    use Object::Quick 'o', 'm';

    package main::I;
    use Object::Quick qw/o m c/;

    package main::J;
    use Object::Quick qw/o m c -class/;

    package main::K;
    use Object::Quick qw/o m c -all/;
}
#}}}

#{{{ A
ok(( !grep { main::A->can( $_ ) } @CLASS_METHODS, @DEFAULTS ), "Imported nothing" );
#}}}
#{{{ B
ok(( !grep { main::B->can( $_ ) } @CLASS_METHODS ), "Did not import class methods" );
is_deeply(
    [ grep { main::B->can( $_ ) } @DEFAULTS ],
    \@DEFAULTS,
    "Imported defaults"
);
#}}}
#{{{ C
ok(( !grep { main::C->can( $_ ) } @DEFAULTS ), "Imported no defaults" );
is_deeply(
    [ grep { main::C->can( $_ ) } @CLASS_METHODS ],
    \@CLASS_METHODS,
    "import class methods"
);
#}}}
#{{{ D
is_deeply(
    [ grep { main::D->can( $_ ) } @DEFAULTS, @CLASS_METHODS ],
    [ @DEFAULTS, @CLASS_METHODS ],
    "Imported everything"
);
#}}}
#{{{ E
ok(( !grep { main::E->can( $_ ) } @CLASS_METHODS, @DEFAULTS ), "Imported no defaults" );
ok( main::E->can( 'o' ), "Imported 'o'" );
#}}}
#{{{ F
ok(( !grep { main::F->can( $_ ) } @CLASS_METHODS, @DEFAULTS ), "Imported no defaults" );
ok( main::F->can( 'o' ), "Imported 'o'" );
ok( main::F->can( 'm' ), "Imported 'm'" );
#}}}
#{{{ I
ok(( !grep { main::I->can( $_ ) } @CLASS_METHODS, @DEFAULTS ), "Imported no defaults" );
ok( main::I->can( 'o' ), "Imported 'o'" );
ok( main::I->can( 'm' ), "Imported 'm'" );
ok( main::I->can( 'c' ), "Imported 'c'" );
#}}}
#{{{ J
ok(( !grep { main::J->can( $_ ) } @DEFAULTS ), "Imported no defaults" );
is_deeply(
    [ grep { main::J->can( $_ ) } @CLASS_METHODS ],
    \@CLASS_METHODS,
    "import class methods"
);
ok( main::J->can( 'o' ), "Imported 'o'" );
ok( main::J->can( 'm' ), "Imported 'm'" );
ok( main::J->can( 'c' ), "Imported 'c'" );
#}}}
#{{{ K
ok(( !grep { main::K->can( $_ ) } @DEFAULTS ), "Imported no defaults" );
is_deeply(
    [ grep { main::K->can( $_ ) } @CLASS_METHODS ],
    \@CLASS_METHODS,
    "import class methods"
);
ok( main::K->can( 'o' ), "Imported 'o'" );
ok( main::K->can( 'm' ), "Imported 'm'" );
ok( main::K->can( 'c' ), "Imported 'c'" );
#}}}

done_testing();
