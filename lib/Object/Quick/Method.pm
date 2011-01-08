package Object::Quick::Method;
use strict;
use warnings;

use Carp qw/croak/;

sub new {
    my $class = shift;
    my ( $code ) = @_;
    croak "Object::Quick::New takes a coderef"
        unless ref $code eq 'CODE';
    return bless( $code, $class );
}

1;
