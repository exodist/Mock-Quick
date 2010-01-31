package Object::Quick;
use strict;
use warnings;
use Object::Quick::Method;
use Carp;

#{{{ POD

=head1 NAME

Object::Quick - Quickly turn a hash into an object.

=head1 DESCRIPTION

An object created from a hash. Every hash key can be used as a method to
get/set the hash element. Creation of a new key is as simple as $obj->newkey(
$val ). Essentially an object oriented interface to a hash.

Actual methods can be added to individual objects as well. Note these methods
are object specific, not class specific. Adding a method to one object will not
add it to others. There are some class methods in the works to help manage
methods.

=head1 WHERE IS THIS USEFUL

This object is very useful in testing code. Sometimes you just need to setup a
simulation of an object. Maybe you also need this simulation to have methods
that return more objects. It was also fun to implement.

The fact is that in almost every case it would be better to create a proper
package for the class you need. Aside from some testing scenarios I cannot
think of a real-world use for this. However you may be able to find a use for
it.

=head1 SYNOPSYS

Use Object-Quick with a quick-create function names. Whatever names you provide
will be used as names of shortcut functions.  Providing no name will not import
any function.  First name is quick object creation, second name is the method
maker, third name is the clear helper for clearing values.

Import the class, bring in shortcut functions:

    use Object::Quick qw/obj vm clear/;

    my $obj = obj( a => 'a' );
    print $obj->a; #prints 'a'

New keys can be added trivially:

    $obj->newkey( 'new key!' );
    print $obj->newkey; #prints 'new key!'

Add a method to the object:

    $obj->do_stuff( vm { my $self = shift; $self->ran( @_ ) });
    $obj->do_stuff( 'Blah' );
    print $obj->ran; #prints 'Blah'

Remove a method from the object:

    $obj->do_stuff( clear );
    ok( !$obj->do_stuff );
    $obj->do_stuff( 'Blah' );
    print $obj->do_stuff; #prints 'Blah'

You can create objects with attributes sharing the names of class-methods

    $obj = obj( new => 'new' );
    print $obj->new; #prints 'new'

You can accomplish the same without shortcuts, but it adds a lot of typing:

    use Object::Quick;

    # Create
    my $obj = Object::Quick->new();

    # Add a custom method
    $obj->sub( Object::Quick::Method->new( sub { 'a' });
    print $obj->sub; # prints 'a'

    # and to clear
    $obj->sub( $Object::Quick::CLEAR );


=head1 EXPORTED FUNCTIONS

Nothing is exported without arguments. The first three arguments are simply
shortcuts to reduce your typing. They are only exported if specified, and they
take whatever name you provide.

You can use the special arguments -obj, -class, and -all as well, see below for
what they do.

=over 4

=item Argument 1 - Quick object constructor

    use Object::Quick 'obj';
    my $obj = obj( a => a );

This function is a shortcut so you don't have to keep typing
Object::Quick->new( ... ). It takes any arguments new() accepts.

=item Argument 2 - Method creator

    use Object::Quick 'obj', 'method';
    my $obj = obj( a => 'a', m => method { 'method' });
    $obj->sub( method { my $self = shift; my @args = @_; return 'stuff' });

This function is used to create a special subref that Object::Quick recognises
as a method, and as such runs it with arguments instead of returning the ref.

=item Argument 3 - Clearer

    use Object::Quick qw/obj method clear/;
    my $obj = obj( a => 'a', m => method { 'method' });
    $obj->sub( method { my $self = shift; my @args = @_; return 'stuff' });

    # Now we can also remove a method from an object
    $obj->sub( clear );

This is primarily used to remove methods from objects.

=item Argument - -obj

    use Object::Quick '-obj';
    # Same as: use Object::Quick qw/obj method clear/;

    $obj = obj( a => method { 'a' });
    $obj->a( clear );

This imports the 3 primary functions with simple names

=item Argument - -class

    use Object::Quick '-class';

Import all class methods in function form so you can use

    method( ... );

Instead of

    Object::Quick->method( ... );

=item Argument - -class

Same as:

    use Object::Quick qw/-obj -class/;

=back

=head1 OBJECT METHODS

Anything that is a legal method name can be used. Can be used to get or set the
attribute of the object. If given an Object::Quick::Method object then all
future calls to that method will run the Method with any arguments provided.
Methods can be cleared by using the $Object::Quick::CLEAR variable as an
argument to the method, that is all the clear() shortcut function does.

At object construction the following methods are added to your object. If you
do not want these methods you can override them by providing your own.

    use Object::Quick 'obj', 'method';

    # Has methods following standard perl object conventions
    my $obj = obj;

    # Leave-out or override some standard object methods.
    my $obj = obj( can => undef, DESTROY => method { ... }, ... );

=over 4

=item $obj->new( key => 'val' )

This will create a new object with all the same methods as the original as well
as any data or methods provided to new().

=item $obj->can( $name )

Always returns a subref, there is never a case where it will return undef on an
object.

    use Object::Quick 'obj';
    my $obj = obj;

    my $sub = $obj->can( 'stuff' );
    $obj->$sub( 'value' );

=item $obj->isa( $package )

Works as expected

=item $obj->DESTROY

Currently does nothing except return true.

=back

=cut

=head1 CLASS METHODS

They can only be used as class methods. When used as object method they will
act like any other accessor. This allows for objects with attributes named
'new', 'import', and 'AUTOLOAD', etc...

When -class is provided as an argument to use, class methods are imported as
functions. Heres an example:

    use Object::Quick 'obj';
    my $obj = obj();
    my $methods Object::Quick->methods( $obj );

Can also be done like this:

    use Object::Quick qw/obj -class/;
    my $obj = obj();
    my $methods = methods( $obj );

Notes:

new(), import(), and AUTOLOAD() are not imported when package is used with -class.

=over 4

=item $obj = $class->new( $hashref )

=item $obj = $class->new( %hash )

=item $obj = $class->new()

The object constructor. Creates a new instance of an object with the provided
hash. If no hash is provided an anonymous one will be created.

=cut

#}}}

our $VERSION = '0.010';
our $AUTOLOAD;
our $MC = 'Object::Quick::Method';
our $CLEAR = \'CLEAR_REF';
our %CLASS_METHODS;
our %OBJECT_METHODS;

# Keeping this sub in a variable so we do not have an inaccessible hash
# element for whatever name this sub would have.
our $PARAM = sub {
    my $self = shift;
    my $param = shift;
    croak( "Accessor did not get param to access" )
        unless $param;
    my ( $value ) = @_;

    my $clear = ref( $value ) && $value == $CLEAR;

    if ( $clear ) {
        delete $self->{ $param };
        return;
    }

    my $current = $self->{ $param };

    # If the param is currently a vmethod, and we are not assigning a new vsub,
    # run the vsub, Also clear if clear is given

    return $self->$current( @_ )
        if ( ref($current) && eval { $current->isa( $MC )})
        && !eval { ref($value) && $value->isa( $MC )};

    # Assign value if there is one
    carp( "$param takes a maximum of one argument, ignoring additional arguments." )
        if @_ > 1;
    ($self->{ $param }) = @_ if @_;

    # Return the value
    carp( "Attribute $param is uninitialized" )
        unless exists $self->{ $param };
    return $self->{ $param };
};

sub import {
    my $class = shift;
    return $class->$PARAM( 'import', @_ ) if ref( $class );

    my %args = map { $_ => 1 } grep { $_ && m/^-/ } @_;

    my @names = grep { $_ ? m/^-/ ? undef : $_ : undef } @_[0 .. 2];
    my @default = qw/obj method clear/;
    if ( $args{ -obj } || $args{ -all }) {
        $names[$_] ||= $default[$_] for 0 .. 2;
    }

    my %subs;
    if ( $args{ -class } || $args { -all } ) {
        for my $method ( keys %CLASS_METHODS ) {
            $subs{ $method } = sub { $class->$method( @_ )};
        }
    }

    $subs{ $names[0] } = sub { $class->new( @_ )}
        if $names[0];

    $subs{ $names[1] } = sub (&){ return $MC->new( @_ )}
        if $names[1];

    $subs{ $names[2] } = sub { return $CLEAR }
        if $names[2];

    my ( $caller ) = caller;
    my $ref_base = $caller . '::';

    while ( my ( $name, $sub ) = each %subs ) {
        my $ref = $ref_base . $name;
        if( defined( &$ref )){
            warn( "Not overriding function: $ref" );
            next;
        }
        no strict 'refs';
        *$ref = $sub;
    }

    1;
}

%OBJECT_METHODS = (
    new => $MC->new( sub {
        my $self = shift;
        my $class = ref( $self );
        my $new = $class->new( @_ );
        $class->inherit( $new, $self );
        return $new;
    }),
    isa => $MC->new( sub { my $self = shift; $self->SUPER::isa( @_ )}),
    DOES => $MC->new( sub { my $self = shift; $self->SUPER::isa( @_ )}),
    VERSION => $MC->new( sub { my $self = shift; return ref( $self )->VERSION( @_ )}),
    # Because of autoload magic can() should return true for everything
    can => $MC->new( sub {
        my $self = shift;
        my ( $arg ) = @_;
        return unless $arg;
        return sub {
            my $self = shift;
            return $self->$PARAM( $arg, @_ );
        };
    }),
    DESTROY => $MC->new( sub { 1 }),
);

sub new {
    my $class = shift;
    return $class->$PARAM( 'new', @_ ) if ref( $class );
    my $proto = @_ ? @_ > 1 ? { @_ } : $_[0] : {};

    $proto = {
        %OBJECT_METHODS,
        %$proto,
    };

    return bless( $proto, $class );
}

sub AUTOLOAD {
    my $self = shift;
    my $param = $AUTOLOAD || 'AUTOLOAD';
    $AUTOLOAD = undef;
    $param =~ s/^.*:://;

    # If we are setting a value make the key exist.
    $self->{ $param } ||= undef if ( @_ );

    my $method = $self->can( $param );

    croak( "$param is not a valid method." )
        unless $method;

    return $self->$method( @_ );
}

=item $clone = $class->clone( $obj )

Clone an Object::Quick object. This is not a deep copy, a new reference is
created and blessed, however it goes no deeper.

=item $hash = $class->methods( $obj )

Returns a hash with all the Methods in the object, method names are the keys.

=item $class->add_methods( $obj, @flags, name => sub { ... }, nameb => sub { ... })

Add the specified methods to $obj. @flags is optional. Flags are any arguments
specified after $obj that start with a '-' up until the first argument that
does not start with a '-'.

Possible Flags:

-replace: Replace existing methods with those being added, normally existing
methods will not be overriden.

=item my $new = $class->instance( $obj, @attributes )

Crate a new instance of the given object; that is create a new object with all
the same methods, but none of the accessor values.

=item $class->inherit( $one, $two, @flags )

Give $one all the methods currently in $two. Existing methods in $one will not
be overriden by those in $two unless the '-replace' flag is specified.

=item $class->class_methods( $obj, @flags )

Give $obj object method forms of all the class methods except for new, import,
and AUTOLOAD. existing methods in $obj will not be overriden unless the
'-replace' flag is specified.

example:

    use Object::Quick 'obj';
    my $obj = obj();
    Object::Quick->class_methods( $obj );

    my $new = $obj->clone;
    my $methods = $obj->methods;
    $obj->inherit( $two );
    $new = $obj->instance;

=cut

%CLASS_METHODS = (
    clone => sub {
        my $class = shift;
        my ($one) = @_;
        return unless $one;
        return bless( { %$one }, $class );
    },
    methods => sub {
        my $class = shift;
        my ( $one ) = @_;
        return unless $one;
        return {
            map {
                my $val = $one->{ $_ };
                eval { $val && $val->isa( $MC )} ? ( $_ => $val ) : ()
            } keys %$one
        };
    },
    add_methods => sub {
        my $class = shift;
        my ($one, @params) = @_;
        my @flags;
        push( @flags, shift( @params )) while $params[0] =~ m/^-/;
        my %methods = @params;
        my $replace = grep { '-replace' } @flags;

        return unless $one and @_ > 2;

        while ( my ( $m, $s ) = each %methods ) {
            next if defined $one->{ $m } && !$replace;
            $one->$m( eval { $s->isa( $MC )} ? $s : $MC->new( $s ));
        }
    },
    instance => sub {
        my $class = shift;
        my ($one, @new) = @_;
        return unless $one;
        return bless( { %{$class->methods( $one )}, @new }, $class );
    },
    inherit => sub {
        my $class = shift;
        my ($one, $two, @flags) = @_;
        my @bad = grep { $_ !~ m/^-/ } @flags;
        croak( "invalid flag(s): " . join( ' ', @bad )) if @bad;

        return unless $one and $two;
        my $methods = $class->methods( $two );
        $class->add_methods( $one, @flags, %$methods );
    },
    class_methods => sub {
        my $class = shift;
        my ( $one, @flags ) = @_;
        my @bad = grep { $_ !~ m/^-/ } @flags;
        croak( "invalid flag(s): " . join( ' ', @bad )) if @bad;

        return unless $one;
        my %subs;
        for my $method ( keys %CLASS_METHODS ) {
            my $sub = $CLASS_METHODS{ $method };
            $subs{ $method } = sub {
                my $self = shift;
                my $class = ref( $self );
                $class->$sub( $self, @_ );
            };
        }
        $class->add_methods( $one, @flags, %subs );
    },
);

for my $method ( keys %CLASS_METHODS ) {
    my $sub = sub {
        my $class = shift;
        return $class->$PARAM( $method, @_ ) if ref( $class );
        return $CLASS_METHODS{ $method }->( $class, @_ );
    };

    no strict 'refs';
    *$method = $sub;
}

for my $method ( qw/ can isa DOES VERSION DESTROY / ) {
    my $sub = sub {
        my $class = shift;

        # Pass it on to the object
        return $class->$PARAM( $method, @_ )
            if ref( $class );

        #Use the UNIVERSAL implementation
        my @params = @_;
        return eval "UNIVERSAL::$method( \$class, \@params )";
    };

    no strict 'refs';
    *$method = $sub;
}

1;

__END__

=back

=head1 MAGIC

=over 4

=item $class->import()

=item $class->import( @args )

Automatically called when you use Object::Quick. The optional arguments are the
names you want to use for the shortcut functions.

=item AUTOLOAD()

This is a special method. This is where the magic happens. Read the perldoc for
AUTOLOAD for more details.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Object-Quick is free software; Standard perl licence.

Object-Quick is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
