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
    my ( $proto ) = @_;

    my $type = ref $proto;

    die( "$class Constructor takes a code reference, an array where the first element is a coderef, or a hashref where code => coderef" )
        unless $type eq 'CODE'
           || ($type eq 'ARRAY' && ref($proto->[0]) eq 'CODE')
           || ($type eq 'HASH' && ref($proto->{ code }) eq 'CODE');

    return bless( $proto, $class );
}

sub run {
    my $self = shift;
    my $type = ref $self;
    my $sub = $type eq 'CODE' ? $self
            : $type eq 'ARRAY' ? $self->[0]
            : $self->{ code };

    my $realself = shift;
    return $realself->$sub( @_ );
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
