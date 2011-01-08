package Object::Quick;
use strict;
use warnings;

use Object::Quick::Util;
use Object::Quick::Method;
use Scalar::Util ();
use Carp ();

our $AUTOLOAD;
our $VERSION = '1.000';
our $CLEAR = \'clear';

our %EXPORT_CACHE = (
    obj => sub { $class->new( @_ )               },
    meth => sub { Object::Quick::Method->new( @_ )},
    clear => sub { $CLEAR                          },
);

alt_method import => (
    obj => sub { my $self = shift; param( $self, 'import', @_ )},
    class => sub {
        my $class = shift;
        my $caller = caller;

        unless ( $_[0] =~ m/^-(.*)$/ ) {
            Object::Quick::Util::_inject( $caller, $_[0], $EXPORT_CACHE{ obj   });
            Object::Quick::Util::_inject( $caller, $_[1], $EXPORT_CACHE{ meth  });
            Object::Quick::Util::_inject( $caller, $_[2], $EXPORT_CACHE{ clear });
            return 1;
        };
        my $param = $&;

        if ($param eq "all") {
            Object::Quick::Util::_inject( $caller, $_, $EXPORT_CACHE{ $_ })
                for keys %EXPORT_CACHE;
            return 1;
        }

        croak "Unknown option '$param'" unless $param =~ m/^conf(ig)?/

        my %params = @_;

        Object::Quick::Util::_inject( $caller, $params{ $_ }, $EXPORT_CACHE{ $_ })
            for keys %params;

        return 1;
    },
);

sub AUTOLOAD {
    my $proto = shift;

    my $sub = $AUTOLOAD || 'AUTOLOAD';
    $AUTOLOAD = undef;
    $sub =~ s/^.*:://;

    Carp::croak( "method '$sub' not found in class $proto" )
        unless Scalar::Util::blessed( $proto );

    my $code = $proto->can( $sub );
    return $code->( $proto, @_ ) if $code;

    Carp::croak( "method '$sub' not found in class $proto" )
        unless Scalar::Util::blessed( $proto );
}

alt_meth new => (
    obj   => sub { my $self = shift; param( $self, 'new', @_ )},
    class => sub {
        my $class = shift;
        return bless( { @_ }, $class );
    },
);

my %PARAM_CACHE;
alt_meth can => (
    class => sub { no warnings 'misc'; return UNIVERSAL::can( @_ )},
    obj   => sub {
        my $self = shift;
        my ( $name ) = @_;

        {
            no warnings 'misc';
            my $normal = UNIVERSAL::can( $name );
            return $normal if $normal;
        }

        my $value = param( $self, $name );
        my $type = Scalar::Util::blessed( $value );

        return $value if $value && $type && $type->isa( 'Object::Quick::Method' );

        $PARAM_CACHE{ $name } ||= sub { my $self = shift; param( $self, $name, @_ )};
        return $PARAM_CACHE{ $name };
    },
);

alt_meth isa => (
    class => sub { no warnings 'misc'; return UNIVERSAL::isa( @_ )},
    obj => sub {
        my $self = shift;
        no warnings 'misc';

        my $isa = UNIVERSAL::isa( $self, @_ );
        return $isa if $isa;

        my $ISA = param( $self, 'ISA' );
        return unless $ISA;

        $ISA = [ $ISA ] unless ref $ISA eq 'ARRAY';

        for my $item ( @$ISA ) {
            next unless $item;
            return 1 if $item->isa( @_ );
        }

        return 0;
    },
);

alt_meth DOES => (
    class => sub { no warnings 'misc'; return UNIVERSAL::DOES( @_ )},
    obj => sub {
        my $self = shift;
        my $param = param( $self, 'DOES' );
        return Scalar::Util::blessed($self)->DOES( @_ )
            unless $param
                && blessed( $param )
                && blessed( $param )->isa( 'Object::Quick::Method' );

        return $param->( $self, @_ );
    },
);

alt_meth VERSION => (
    class => sub { no warnings 'misc'; return UNIVERSAL::VERSION( @_ )},
    obj => sub {
        my $self = shift;
        my $param = param( $self, 'DOES' );
        return Scalar::Util::blessed($self)->VERSION( @_ )
            unless $param
                && blessed( $param )
                && blessed( $param )->isa( 'Object::Quick::Method' );

        return $param->( $self, @_ );
    },
);

alt_meth DESTROY => (
    class => sub { 1 },
    obj => sub {
        my $self = shift;
        my $param = param( $self, 'DOES' );
        return 1 unless $param
                     && blessed( $param )
                     && blessed( $param )->isa( 'Object::Quick::Method' );

        return $param->( $self, @_ );
    },
);

1;
