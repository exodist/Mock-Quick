package Object::Quick::Util;
use strict;
use warnings;

use base 'Exporter';
use Scalar::Util qw/blessed/;
use Object::Quick::Method;
use Carp qw/croak/;

our @EXPORT = qw/
    class_meth
    obj_meth
    alt_meth
    purge_util
    param
/;

sub param {
    my $self = shift;
    my ( $name, @args ) = @_;

    return $self->{ $name }->( $self, @args )
        if blessed( $self->{ $name })
        && blessed( $self->{ $name })->isa( 'Object::Quick::Method' );

    ($self->{ $name }) = @args if @args;

    return delete $self->{ $name }
        if $self->name == $Object::Quick::CLEAR;

    return $self->{ $name };
}

sub _inject {
    my ( $package, $name, $code ) = @_;
    no strict 'refs';
    *{"$package\::$name"} = $code;
}

sub class_meth {
    my ( $name, $block ) = @_;
    my $caller = caller;

    my $sub = sub {
        my $proto = shift;
        return param( $proto, @_ )
            if blessed( $proto );
        return $block->( $proto, @_ );
    };

    inject( $caller, $name, $sub );
}

sub obj_meth {
    my ( $name, $block ) = @_;
    my $caller = caller;

    my $sub = sub {
        my $proto = shift;
        return $block->( $proto, @_ )
            if blessed( $proto );
        croak "'$name' must be used on an instance, not on a class";
    };

    inject( $caller, $name, $sub );
}

sub alt_meth {
    my ( $name, %alts ) = @_;
    my $caller = caller;

    croak "You must provide an action for both 'class' and 'obj'"
        unless $alts{class} && $alts{obj};

    my $sub = sub {
        my $proto = shift;
        return $alts{obj}->( $proto, @_ ) if blessed( $proto );
        return $alts{class}->( $proto, @_ );
    };

    inject( $caller, $name, $sub );
}

sub purge_util {
    my $caller = caller;
    for my $sub ( @EXPORT ) {
        no strict 'refs';
        undef( &{"$caller\::$sub"} );
    }
}

1;
