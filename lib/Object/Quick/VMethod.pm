package Object::Quick::VMethod;
use strict;
use warnings;

sub new {
    my $class = shift;
    my ( $sub ) = @_;
    die( "$class Constructor takes a code reference." )
        unless ref( $sub ) eq 'CODE';
    return bless( $sub, $class );
}

1;
