package Object::Quick;
use strict;
use warnings;

#{{{ POD

=head1 NAME

Object-Quick - Quickly turn a hash into an object.

=head1 DESCRIPTION

An object created from a hash. Every hash key can be used as a method to
get/set the hash element. Creation of a new key is as simple as $obj->newkey(
$val ). Essentially an object oriented interface to a hash.

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

    $obj = obj( a => obj( a => 'a' );
    print $obj->a->a; #prints 'a'

    # You can create objects with attriubtes sharing the names of class-methods
    $obj = obj( new => 'new' );
    print $obj->new; #prints 'new'

    # New keys can be added trivially
    $obj->newkey( 'new key!' );
    print $obj->newkey; #prints 'new key!'

    #You can create objets using the package as well:
    $obj = Object::Quick->new();

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

our $VERSION = 0.001;
our $AUTOLOAD;

# Keeping this sub in a variable so we do not have an inaccessible hash
# element for whatever name this sub would have.
our $PARAM = sub {
    my $self = shift;
    my $param = shift;

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
    return bless( @_ ? @_ > 1 ? { @_ } : $_[0] : {}, $class );
}

sub AUTOLOAD {
    my $self = shift;
    my $param = $AUTOLOAD || 'AUTOLOAD';
    $AUTOLOAD = undef;

    $param =~ s/^.*:://;
    return $self->$PARAM( $param, @_ );
}

1;

__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

App-PDT is free software; Standard perl licence.

App-PDT is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
