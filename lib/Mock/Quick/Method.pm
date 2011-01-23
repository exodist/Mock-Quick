package Mock::Quick::Method;
use strict;
use warnings;

use Carp ();

sub new {
    my $class = shift;
    my ($sub) = @_;
    Carp::croak "Constructor to $class takes a single codeblock"
        unless ref $sub eq 'CODE';
    return bless $sub, $class;
}

1;
