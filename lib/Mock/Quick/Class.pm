package Mock::Quick::Class;
use strict;
use warnings;

use Mock::Quick::Util;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;

our $ANON = 'AAAAAAAAAA';

sub package { shift->{'-package'}}

sub takeover {
    my $class = shift;
    my ( $package ) = @_;
    return bless( { -package => $package, -takeover => 1 }, $class );
}

alt_meth new => (
    obj   => sub { my $self = shift; $self->package->new(@_) },
    class => sub {
        my $class = shift;
        my %params = @_;
        my $package = __PACKAGE__ . "::__ANON__::" . $ANON++;

        my $self = bless( { %params, -package => $package }, $class );

        for my $key ( keys %params ) {
            my $value = $params{$key};

            if ( $key =~ m/^-/ ) {
                $self->configure( $key, $value );
            }
            elsif( _is_sub_ref( $value )) {
                inject( $package, $key, $value );
            }
            else {
                inject( $package, $key, sub { $value });
            }
        }

        return $self;
    }
);

sub configure {
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
    my ( $name, $orig_value ) = @_;
    my $real_value = _is_sub_ref( $orig_value )
        ? $orig_value
        : sub { $orig_value };

    my $original = $package->can( $name );
    $self->{$name} ||= $original;
    inject( $package, $name, $real_value );
    return $original;
}

sub restore {
    my $self = shift;
    my ( $name ) = @_;
    my $original = $self->{$name};

    if ( $original ) {
        my $sub = _is_sub_ref( $original ) ? $original : sub { $original };
        inject( $self->package, $name, $sub );
    }
    else {
        $self->clear( $name );
    }
}

sub clear {
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
        if $self->{'-takeover'};
    no strict 'refs';
    undef( *{"$package\::"} );
}

sub DESTROY {
    my $self = shift;
    return unless $self->{'-takeover'};
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

=head2 MOCKING CLASSES

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

=head2 TAKING OVER EXISTING CLASSES

    use Mock::Quick::Class;

    my $control = Mock::Quick::Class->takeover( 'Some::Package' );

    # Override a method
    $control->override( foo => sub { ... });

    # Restore it to the original
    $control->restore( 'foo' );

    # Destroy the control object and completely restore the original class Some::Package.
    $control = undef;

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Mock-Quick is free software; Standard perl licence.

Mock-Quick is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.
