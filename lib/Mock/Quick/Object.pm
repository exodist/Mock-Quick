package Mock::Quick::Object;
use strict;
use warnings;

use Mock::Quick::Util;
use Carp ();
use Scalar::Util ();

our $AUTOLOAD;

class_meth new => sub {
    my $class = shift;
    my %proto = @_;
    return bless \%proto, $class;
};

sub AUTOLOAD {
    # Do not shift this, we need it when we use goto &$sub
    my ($self) = @_;
    my ( $package, $sub ) = ( $AUTOLOAD =~ m/^(.+)::([^:]+)$/ );
    $AUTOLOAD = undef;

    Carp::croak "Can't locate object method \"$sub\" via package \"$package\""
        unless Scalar::Util::blessed( $self );

    goto &{ $self->can( $sub )};
};

alt_meth can => (
    class => sub { no warnings 'misc'; goto &UNIVERSAL::can },
    obj => sub {
        my ( $self, $name ) = @_;
        my $sub;
        {
            no warnings 'misc';
            $sub = UNIVERSAL::can( $self, $name );
        }
        $sub ||= sub {
            unshift @_ => ( shift( @_ ), $name );
            goto &call;
        };
        inject( Scalar::Util::blessed( $self ), $name, $sub );
        return $sub;
    },
);

# http://perldoc.perl.org/perlobj.html#Default-UNIVERSAL-methods
# DOES is equivilent to isa by default
sub isa     { no warnings 'misc'; goto &UNIVERSAL::isa     }
sub DOES    { goto &isa                                    }
sub VERSION { no warnings 'misc'; goto &UNIVERSAL::VERSION }

obj_meth DESTROY => sub {
    unshift @_ => ( shift( @_ ), 'DESTROY' );
    goto &call;
};

purge_util();

1;
