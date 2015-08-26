use strict;
use warnings;

use Test::More;

use Mock::Quick;
use Path::Class;

my $x = qobj(foo => qmeth { print "# My file is $_[1]\n" });

my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings => @_ };
    $x->foo( file(".") );
}
ok(!@warnings, "No warnings") || print STDERR @warnings;

done_testing;
