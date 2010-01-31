package Object::Quick::Method;
use strict;
use warnings;

#{{{ POD

=head1 NAME

Object::Quick::Method - Methods for Object::Quick objects.

=head1 DESCRIPTION

These are blessed codrefs used by Object::Quick to insert methods into objects.
If an Object::Quick::Method object is assigned to an accessor in an
Object::Quick object, that method will be run whenever the accessor is used in
the future.

=head1 SYNOPSYS

    use Object::Quick::Method;
    my $method = Object::Quick::Method->new( sub { ... });

=head1 CLASS METHODS

=over 4

=item $method = $class->new( sub {...} )

Constructor, takes a coderef as the only argument.

=cut

#}}}

sub new {
    my $class = shift;
    my ( $sub ) = @_;
    die( "$class Constructor takes a code reference." )
        unless ref( $sub ) eq 'CODE';
    return bless( $sub, $class );
}

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
