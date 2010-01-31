package Object::Quick::Strict;
use strict;
use warnings;

use base 'Object::Quick';

#{{{ POD

=head1 NAME

Object::Quick::Strict - Stricter form of Object::Quick

=head1 DESCRIPTION

See the docs for L<Object::Quick>. Object::Quick::Strict can be used as a
drop-in replacement for Object::Quick, the only differences are listed in the
DIFFERENCES section.

=head1 SYNOPSYS

You cannot use a method until it is initialized either during construction or
by assigning a value.

    use Object::Quick::Strict qw/obj method clear/;
    my $one = obj( a => a, method => method { ... } );
    ok( $one->a, "a accessor works" );
    ok( !$one->can( 'b' ), "Object does not have a 'b' method" )
    ok( !eval { $one->b }, "trying to use the 'b' method will die" );
    print $@; #Prints that 'b' is not a valid method

You can easily initialize a method

    # This will not die, it will initialize 'b' for you.
    $one->b( 'b' );

=head1 DIFFERENCES

=over 4

=item $obj->can()

Can return undef unless the accessor has been initialized wither through the
constructor, or by assigning a value.

=item $obj->something()

Unless the accessor 'something' has been assigned a value this will die.

=cut

#}}}

sub can {
    my $self = shift;
    my ( $arg ) = @_;
    return unless $arg;

    return if ref( $self ) && !exists $self->{ $arg };

    return $self->SUPER::can( @_ );
};

1;

__END__

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Object-Quick is free software; Standard perl licence.

Object-Quick is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the license for more details.
