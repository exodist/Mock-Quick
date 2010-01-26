package Object::Quick;
use strict;
use warnings;

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

    # Use Object-Quick with a quick-create function name.
    # Whatever name you provide will be used to create a function that converts
    # any hash into an object. Providing no name will not import any function.

    use Object::Quick 'obj';

    my $obj = obj( a => 'a' );
    print $obj->a; #prints 'a'

    $obj = obj( a => obj( a => 'a' ));
    print $obj->a->a; #prints 'a'

    # You can create objects with attriubtes sharing the names of class-methods
    $obj = obj( new => 'new' );
    print $obj->new; #prints 'new'

    # New keys can be added trivially
    $obj->newkey( 'new key!' );
    print $obj->newkey; #prints 'new key!'

    #You can create objets using the package as well:
    $obj = Object::Quick->new();

    #Add a method to the object:
    $obj->do_stuff( 'method', sub { my $self = shift; $self->ran( @_ ) });
    $obj->do_stuff( 'Blah' );
    print $obj->ran; #prints 'Blah'

    #Clear a method
    $obj->do_stuff( 'method', undef );
    $obj->do_stuff( 'Blah' );
    print $obj->do_stuff; #prints 'Blah'

=head1 EXPORTED FUNCTIONS

There is only one exported function, that is the quick-convert function. It is
only imported when requested. To import the function add the name you which it
to use as an argument to use Object::Quick.

    use Object::Quick 'quick_convert_function_name';

This function is a shortcut so you don't have to keep typing
Object::Quick->new( ... ). It takes any arguments new() accepts.

=head1 CLASS METHODS

There are only 3 class methods. They can only be used as class methods. When
used as object method they will act like any other accessor. This allows for
objects with attributes named 'new', 'import', and 'AUTOLOAD'.

=over 4

=item $obj = $class->new( $hashref )

=item $obj = $class->new( %hash )

=item $obj = $class->new()

The object constructor. Creates a new instance of an object with the provided
hash. If no hash is provided an anonymous one will be created.

=item $class->import()

=item $class->import( $quick_create_name )

Automatically called when you use Object::Quick. The optional argument is the
name you want to use for the quick create method.

=item AUTOLOAD()

This is a special method. This is where the magic happens. Read the perldoc for
AUTOLOAD for more details.

=back

=head1 OBJECT METHODS

Anything that is a legal method name can be used. Can be used to get or set the
attribute of the object.

=cut

#}}}

our $VERSION = 0.005;
our $AUTOLOAD;

# Keeping this sub in a variable so we do not have an inaccessible hash
# element for whatever name this sub would have.
our $PARAM = sub {
    my $self = shift;
    my $param = shift;
    my ( $set_vm, $val ) = @_;
    $set_vm = $set_vm
           && $set_vm =~ m/^method$/i
           && @_ > 1
           && (
                ( !defined( $val ))
            ||
                ( ref( $val ) && ref( $val ) eq 'CODE' )
           );

    my $current = $self->{ $param };
    my $vmethod = ($current && eval { $current->isa( $VM_CLASS ) }) ? 1 : 0;

    return $current->( $self, @_ )
        if ( $vmethod && !$set_vm );

    if ( $set_vm ) {
        if ( defined $val ) {
            $self->{ $param } = bless( $val, $VM_CLASS );
            return !! $self->{ $param };
        }
        else {
            delete $self->{ $param };
            return ! exists $self->{ $param };
        }
    }

    ($self->{ $param }) = @_ if @_;
    return $self->{ $param };
};

sub import {
    my $class = shift;
    return $class->$PARAM( 'import', @_ ) if ref( $class );

    my ( $name ) = @_;
    return unless $name;

    my ( $caller ) = caller;
    my $ref = $caller . '::' . $name;

    no strict 'refs';
    return if defined( &$ref );
    *$ref = sub { $class->new( @_ )};
}

sub new {
    my $class = shift;
    return $class->$PARAM( 'new', @_ ) if ref( $class );
    my ( $proto, %meta ) = @_;
    my $methods = { map { $_ => 1 } @{ delete $meta{ methods }}
        if $meta{ methods };

    return bless( [ $proto, $methods, \%meta ], $class );
}

sub AUTOLOAD {
    my $self = shift;
    my $param = $AUTOLOAD || 'AUTOLOAD';
    $AUTOLOAD = undef;

    $param =~ s/^.*:://;
    return $self->$PARAM( $param, @_ );
}

our %CLASS_METHODS = (
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
                eval { $val->isa( $VM_CLASS )} ? ( $_ => $val ) : ()
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
            $one->$m( 'method', $s );
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
        $methods = $class->methods( $two );
        $class->add_methods( $one, %$methods );
    },
    merge_methods => sub {},
    class_methods => sub {},
    
);

for my $method ( keys %CLASS_METHODS ) {
    *$method = sub {
        my $class = shift;
        return $class->$PARAM( $method, @_ ) if ref( $class );
        return $CLASS_METHODS->{ $method }->( $class, @_ );
    };
}
1;

__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Object-Quick is free software; Standard perl licence.

Object-Quick is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
