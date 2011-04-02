package Mock::Quick::Class;
use strict;
use warnings;

use Mock::Quick::Util;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

our $ANON = 'AAAAAAAAAA';

sub package      { shift->{'-package'}  }
sub inc          { shift->{'-inc'}      }
sub is_takeover  { shift->{'-takeover'} }
sub is_implement { shift->{'-implement'}}

sub takeover {
    my $class = shift;
    my ( $package, %params ) = @_;

    my $self = bless( { -package => $package, -takeover => 1 }, $class );

    for my $key ( keys %params ) {
        croak "param '$key' is not valid in a takeover"
            if $key =~ m/^-/;
        $self->override( $key => $params{$key} );
    }

    return $self;
}

sub implement {
    my $class = shift;
    my ( $package, %params ) = @_;
    my $caller = delete $params{'-caller'} || [caller()];

    my $inc = $package;
    $inc =~ s|::|/|g;
    $inc .= '.pm';

    croak "$package has already been loaded, cannot implement it."
        if $INC{$inc};

    $INC{$inc} = $caller->[1];

    my $self = bless(
        { -package => $package, -implement => 1, -inc => $inc },
        $class
    );

    $self->_configure( %params );

    return $self;
}

alt_meth new => (
    obj   => sub { my $self = shift; $self->package->new(@_) },
    class => sub {
        my $class = shift;
        my %params = @_;

        croak "You cannot combine '-takeover' and '-implement' arguments"
            if $params{'-takeover'} && $params{'-implement'};

        return $class->takeover( delete( $params{'-takeover'} ), %params )
            if $params{'-takeover'};

        return $class->implement( delete( $params{'-implement'} ), %params )
            if $params{'-implement'};

        my $package = __PACKAGE__ . "::__ANON__::" . $ANON++;

        my $self = bless( { %params, -package => $package }, $class );

        $self->_configure( %params );

        return $self;
    }
);

sub _configure {
    my $self = shift;
    my %params = @_;
    my $package = $self->package;

    for my $key ( keys %params ) {
        my $value = $params{$key};

        if ( $key =~ m/^-/ ) {
            $self->_configure_pair( $key, $value );
        }
        elsif( _is_sub_ref( $value )) {
            inject( $package, $key, $value );
        }
        else {
            inject( $package, $key, sub { $value });
        }
    }
}

sub _configure_pair {
    my $self = shift;
    my ( $param, $value ) = @_;
    my $package = $self->package;

    if ( $param eq '-subclass' ) {
        $value = [ $value ] unless ref $value eq 'ARRAY';
        no strict 'refs';
        push @{"$package\::ISA"} => @$value;
    }
    elsif ( $param eq '-attributes' ) {
        $value = [ $value ] unless ref $value eq 'ARRAY';
        for my $attr ( @$value ) {
            inject( $package, $attr, sub {
                my $self = shift;
                croak "$attr() called on '$self' instead of an instance"
                    unless blessed( $self );
                ( $self->{$attr} ) = @_ if @_;
                return $self->{$attr};
            });
        }
    }
    elsif ( $param eq '-with_new' ) {
        inject( $package, 'new', sub {
            my $class = shift;
            croak "new() cannot be called on an instance"
                if blessed( $class );
            my %proto = @_;
            return bless( \%proto, $class );
        });
    }
}

sub _is_sub_ref {
    my $in = shift;
    my $type = ref $in;
    my $class = blessed( $in );

    return 1 if $type && $type eq 'CODE';
    return 1 if $class && $class->isa( 'Mock::Quick::Method' );
    return 0;
}

sub override {
    my $self = shift;
    my $package = $self->package;
    my %pairs = @_;
    my @originals;

    for my $name ( keys %pairs ) {
        my $orig_value = $pairs{$name};

        my $real_value = _is_sub_ref( $orig_value )
            ? $orig_value
            : sub { $orig_value };

        my $original = $package->can( $name );
        $self->{$name} ||= $original;
        inject( $package, $name, $real_value );

        push @originals, $original;
    }

    return @originals;
}

sub restore {
    my $self = shift;

    for my $name ( @_ ) {
        my $original = $self->{$name};

        if ( $original ) {
            my $sub = _is_sub_ref( $original ) ? $original : sub { $original };
            inject( $self->package, $name, $sub );
        }
        else {
            $self->_clear( $name );
        }
    }
}

sub _clear {
    my $self = shift;
    my ( $name ) = @_;
    my $package = $self->package;
    no strict 'refs';
    my $ref = \%{"$package\::"};
    delete $ref->{ $name };
}

sub undefine {
    my $self = shift;
    my $package = $self->package;
    croak "Refusing to undefine a class that was taken over."
        if $self->is_takeover;
    no strict 'refs';
    undef( *{"$package\::"} );
    delete $INC{$self->inc} if $self->is_implement;
}

sub DESTROY {
    my $self = shift;
    return unless $self->is_takeover;
    for my $sub ( keys %{$self} ) {
        next if $sub =~ m/^-/;
        $self->restore( $sub );
    }
}

purge_util();

1;

__END__

=head1 NAME

Mock::Quick::Class - Class mocking for Mock::Quick

=head1 DESCRIPTION

Provides class mocking for L<Mock::Quick>

=head1 SYNOPSIS

=head2 IMPLEMENT A CLASS

This will implement a class at the namespace provided via the -implement
argument. The class must not already be loaded. Once complete the real class
will be prevented from loading until you call undefine() on the control object.

    use Mock::Quick::Class;

    my $control = Mock::Quick::Class->new(
        -implement => 'My::Package',

        # Insert a generic new() method (blessed hash)
        -with_new => 1,

        # Inheritance
        -subclass => 'Some::Class',
        # Can also do
        -subclass => [ 'Class::A', 'Class::B' ],

        # generic get/set attribute methods.
        -attributes => [ qw/a b c d/ ],

        # Method that simply returns a value.
        simple => 'value',

        # Custom method.
        method => sub { ... },
    );

    my $obj = $control->package->new;
    # OR
    my $obj = My::Package->new;

    # Override a method
    $control->override( foo => sub { ... });

    # Restore it to the original
    $control->restore( 'foo' );

    # Remove the namespace we created, which would allow the real thing to load
    # in a require or use statement.
    $control->undefine();

You can also use the 'implement' method instead of new:

    use Mock::Quick::Class;

    my $control = Mock::Quick::Class->implement(
        'Some::Package',
        %args
    );

=head2 ANONYMOUS MOCKED CLASS

This is if you just need to generate a class where the package name does not
matter. This is done when the -takeover and -implement arguments are both
ommited.

    use Mock::Quick::Class;

    my $control = Mock::Quick::Class->new(
        # Insert a generic new() method (blessed hash)
        -with_new => 1,

        # Inheritance
        -subclass => 'Some::Class',
        # Can also do
        -subclass => [ 'Class::A', 'Class::B' ],

        # generic get/set attribute methods.
        -attributes => [ qw/a b c d/ ],

        # Method that simply returns a value.
        simple => 'value',

        # Custom method.
        method => sub { ... },
    );

    my $obj = $control->package->new;

    # Override a method
    $control->override( foo => sub { ... });

    # Restore it to the original
    $control->restore( 'foo' );

    # Remove the anonymous namespace we created.
    $control->undefine();

=head2 TAKING OVER EXISTING/LOADED CLASSES

    use Mock::Quick::Class;

    my $control = Mock::Quick::Class->takeover( 'Some::Package' );

    # Override a method
    $control->override( foo => sub { ... });

    # Restore it to the original
    $control->restore( 'foo' );

    # Destroy the control object and completely restore the original class
    # Some::Package.
    $control = undef;

You can also do this through new()

    use Mock::Quick::Class;

    my $control = Mock::Quick::Class->new(
        -takeover => 'Some::Package',
        %overrides
    );

=head1 AUTHORS

=over 4

=item Chad Granum L<exodist7@gmail.com>

=item Glen Hinkle L<glen@empireenterprises.com>

=back

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Mock-Quick is free software; Standard perl licence.

Mock-Quick is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.
