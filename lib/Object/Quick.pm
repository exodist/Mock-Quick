package Object::Quick;
use strict;
use warnings;
use Object::Quick::VMethod;

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

I urge strongly against using this magic in production code. This object is
however very useful in testing code. Sometimes you just need to setup a
simulation of an object. Maybe you also need this simulation to have methods
that return more objects.

=head1 SYNOPSYS

Use Object-Quick with a quick-create function names. Whatever names you provide
will be used as names of shortcut functions.  Providing no name will not import
any function.  First name is quick object creation, second name is the method
maker, third name is the clear helper for clearing values.

    # Import the class, bring in shortcut functions
    use Object::Quick qw/obj vm clear/;

    my $obj = obj( a => 'a' );
    print $obj->a; #prints 'a'

    $obj = obj( a => obj( a => 'a' ));
    print $obj->a->a; #prints 'a'

    # You can create objects with attributes sharing the names of class-methods
    $obj = obj( new => 'new' );
    print $obj->new; #prints 'new'

    # New keys can be added trivially
    $obj->newkey( 'new key!' );
    print $obj->newkey; #prints 'new key!'

    #You can create objets using the package as well:
    $obj = Object::Quick->new();

    #Add a method to the object:
    $obj->do_stuff( vm { my $self = shift; $self->ran( @_ ) });
    $obj->do_stuff( 'Blah' );
    print $obj->ran; #prints 'Blah'

    #Clear a method
    $obj->do_stuff( clear );
    ok( !$obj->do_stuff );
    $obj->do_stuff( 'Blah' );
    print $obj->do_stuff; #prints 'Blah'

You can accomplish the same without shortcuts, but it adds a lot of typing:

    use Object::Quick;

    # Create
    my $obj = Object::Quick->new();

    # Add a custom method
    $obj->sub( Object::Quick::VMethod->new( sub { 'a' });
    print $obj->sub; # prints 'a'

    # and to clear
    $obj->sub( $Object::Quick::CLEAR );

=head1 EXPORTED FUNCTIONS

The first three arguments are simply shortcuts to reduce your typing. They are
only exported if specified, and they take whatever name you provide. All other
arguments should be the names of class methods for which you want shortcuts.

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

    use Object::Quick qw/obj method clear/
    my $obj = obj( a => 'a', m => method { 'method' });
    $obj->sub( method { my $self = shift; my @args = @_; return 'stuff' });

    # Now we can also remove a method from an object
    $obj->sub( clear );

This is primarily used to remove methods from objects.

=item Argument - -obj

    use Object::Quick '-obj';

    $obj = obj( a => method { 'a' });
    $obj->a( clear );

This imports the 3 primary functions with simple names

=item Argument - -class

    use Object::Quick '-class';

Import all class methods in function form so you can use

    method( ... );

Instead of

    Object::Quick->method( ... );

=back

=head1 OBJECT METHODS

Anything that is a legal method name can be used. Can be used to get or set the
attribute of the object. If given an Object::Quick::VMethod object then all
future calls to that method will run the VMethod with any arguments provided.
VMethods can be cleared by using the $Object::Quick::CLEAR variable as an
argument to the method, that is all the clear() shortcut function does.

=cut

=head1 CLASS METHODS

They can only be used as class methods. When used as object method they will
act like any other accessor. This allows for objects with attributes named
'new', 'import', and 'AUTOLOAD', etc...

=over 4

=item $obj = $class->new( $hashref )

=item $obj = $class->new( %hash )

=item $obj = $class->new()

=cut

#}}}

our $VERSION = 0.006;
our $AUTOLOAD;
our $VMC = 'Object::Quick::VMethod';
our $CLEAR = \'CLEAR_REF';
our %CLASS_METHODS;

# Keeping this sub in a variable so we do not have an inaccessible hash
# element for whatever name this sub would have.
our $PARAM = sub {
    my $self = shift;
    my $param = shift;
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
        if ( ref($current) && eval { $current->isa( $VMC )})
        && !eval { ref($value) && $value->isa( $VMC )};

    # Assign value if there is one
    ($self->{ $param }) = @_ if @_;

    # Return the value
    return $self->{ $param };
};

sub import {
    my $class = shift;
    return $class->$PARAM( 'import', @_ ) if ref( $class );

    my %args = map { $_ => 1 } grep { m/^-/ } @_;

    my @names = grep { $_ ? m/^-/ ? undef : $_ : undef } @_[0 .. 2];
    my @default = qw/obj method clear/;
    if ( $args{ -obj } || $args{ -all }) {
        $names[$_] ||= $default[$_] for 0 .. 2;
    }

    my %subs;

    %subs = map {
        $_ => sub { $class->$_( @_ )}
    } keys %CLASS_METHODS
        if $args{ -class } || $args { -all };

    $subs{ $names[0] } = sub { $class->new( @_ )}
        if $names[0];

    $subs{ $names[1] } = sub (&){ return $VMC->new( @_ )}
        if $names[1];

    $subs{ $names[2] } = sub { return $CLEAR }
        if $names[2];

    my ( $caller ) = caller;
    my $ref_base = $caller . '::';

    while ( my ( $name, $sub ) = each %subs ) {
        no strict 'refs';
        my $ref = $ref_base . $name;
        return if defined( &$ref );
        *$ref = $sub;
    }

    1;
}

sub new {
    my $class = shift;
    return $class->$PARAM( 'new', @_ ) if ref( $class );
    return bless( @_ ? @_ > 1 ? { @_ } : $_[0] : {}, $class );
}

sub AUTOLOAD {
    my $self = shift;
    my $param = $AUTOLOAD || 'AUTOLOAD';
    $AUTOLOAD = undef;

    $param =~ s/^.*:://;
    return $self->$PARAM( $param, @_ );
}

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
                eval { $val && $val->isa( $VMC )} ? ( $_ => $val ) : ()
            } keys %$one
        };
    },
    add_methods => sub {
        my $class = shift;
        my ($one, %methods) = @_;
        return unless $one and @_ > 2;

        while ( my ( $m, $s ) = each %methods ) {
            if (defined $one->{ $m }) {
                warn "$m() has a value, or is already a method, not replacing.";
                next;
            }
            $one->$m( eval { $s->isa( $VMC )} ? $s : $VMC->new( $s ));
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
        my ($one, $two) = @_;
        return unless $one and $two;
        my $methods = $class->methods( $two );
        $class->add_methods( $one, %$methods );
    },
    class_methods => sub {
        my $class = shift;
        my $one = shift;
        return unless $one;
        my %subs = map {
            $_ => sub {
                my $self = shift;
                my $class = ref( $self );
                $class->$_( $self, @_ );
            }
        } keys %CLASS_METHODS;
        $class->add_methods( $one, %subs );
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
1;

__END__

=back

=head1 MAGIC

The object constructor. Creates a new instance of an object with the provided
hash. If no hash is provided an anonymous one will be created.

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
