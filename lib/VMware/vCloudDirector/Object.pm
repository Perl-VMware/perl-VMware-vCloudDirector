package VMware::vCloudDirector::Object;

# ABSTRACT: Module to contain an object!

use strict;
use warnings;

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;
use Ref::Util qw(is_plain_hashref);
use VMware::vCloudDirector::ObjectContent;

# ------------------------------------------------------------------------

has api => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector::API',
    required      => 1,
    weak_ref      => 1,
    documentation => 'API we use'
);

has content => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector::ObjectContent',
    predicate     => 'has_content',
    writer        => '_set_content',
    documentation => 'The underlying content object',
    handles       => [qw( mime_type href type name )],
);

has _partial_object => ( is => 'rw', isa => 'Bool', default => 0 );

# delegates that force a full object to be pulled
method hash () { return $self->inflate->content->hash; }
method links () { return $self->inflate->content->links; }
method id () { return $self->inflate->content->id; }

# ------------------------------------------------------------------------
method BUILD ($args) {

    $self->_set_content(
        VMware::vCloudDirector::ObjectContent->new( object => $self, hash => $args->{hash} ) );
}

# ------------------------------------------------------------------------
method inflate () {
    $self->refetch if ( $self->_partial_object );
    return $self;
}

# ------------------------------------------------------------------------
method refetch () {
    my $hash = $self->api->GET_hash( $self->href );
    $self->_set_content(
        VMware::vCloudDirector::ObjectContent->new( object => $self, hash => $hash ) );
    $self->_partial_object(0);
    return $self;
}

# ------------------------------------------------------------------------

=head3 find_links

Returns any links found that match the search criteria.  The possible criteria
are:-

=over 4

=item name

The name of the link

=item type

The type of the link (short type, not full MIME type)

=item rel

The rel of the link

=back

The return value is a list of link objects.

=cut

method find_links (:$name, :$type, :$rel) {
    my @matched_links;
    my $links = $self->links;
    foreach my $link ( @{$links} ) {
        if ( not( defined($rel) ) or ( $rel eq ( $link->rel || '' ) ) ) {
            if ( not( defined($type) ) or ( $type eq ( $link->type || '' ) ) ) {
                if ( not( defined($name) ) or ( $name eq ( $link->name || '' ) ) ) {
                    push( @matched_links, $link );
                }
            }
        }
    }
    return @matched_links;
}

# ------------------------------------------------------------------------

=head3 fetch_links

As per L</find_links> except that each link found is fetched and expanded up as
an object.

=cut

method fetch_links (@search_items) {
    my @matched_objects;
    foreach my $link ( $self->find_links(@search_items) ) {
        push( @matched_objects, $link->GET() );
    }
    return @matched_objects;
}

# ------------------------------------------------------------------------

=head3 DELETE

Make a delete request to the URL of this object.  Returns Objects.  Failure
will generate an exception.  See L<VMware::vCloudDirector::API/DELETE>.

=cut

method DELETE () { return $self->api->GET( $self->href ); }

=head3 GET

Make a get request to the URL of this object.  Returns Objects.  Failure will
generate an exception.  See L<VMware::vCloudDirector::API/GET>.

=cut

method GET () { return $self->api->GET( $self->href ); }

=head3 POST

Make a post request with the specified payload to the URL of this object.
Returns Objects.  Failure will generate an exception.  See
L<VMware::vCloudDirector::API/POST>.

=cut

method POST ($xml_hash) { return $self->api->GET( $self->href, $xml_hash ); }

=head3 PUT

Make a put request with the specified payload to the URL of this object.
Returns Objects.  Failure will generate an exception.  See
L<VMware::vCloudDirector::API/PUT>.

=cut

method PUT ($xml_hash) { return $self->api->GET( $self->href, $xml_hash ); }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
