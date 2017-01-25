package VMware::vCloudDirector::Object;

# ABSTRACT: Module to contain an object!

use strict;
use warnings;

our $VERSION = '0.001'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

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


method find_links (:$name, :$type, :$rel) {
    my @matched_links;
    my $links = $self->links;
    foreach my $link ($links) {

        #foreach my $link ( @{ $self->links } ) {
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


method DELETE () { return $self->api->GET( $self->href ); }


method GET () { return $self->api->GET( $self->href ); }


method POST ($xml_hash) { return $self->api->GET( $self->href, $xml_hash ); }


method PUT ($xml_hash) { return $self->api->GET( $self->href, $xml_hash ); }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloudDirector::Object - Module to contain an object!

=head1 VERSION

version 0.001

=head2 find_links

Returns any links found that match the search criteria

=head3 DELETE

Make a delete request to the URL of this object.  Returns Objects.  Failure
will generate an exception.  See L<VMware::vCloudDirector::API/DELETE>.

=head3 GET

Make a get request to the URL of this object.  Returns Objects.  Failure will
generate an exception.  See L<VMware::vCloudDirector::API/GET>.

=head3 POST

Make a post request with the specified payload to the URL of this object.
Returns Objects.  Failure will generate an exception.  See
L<VMware::vCloudDirector::API/POST>.

=head3 PUT

Make a put request with the specified payload to the URL of this object.
Returns Objects.  Failure will generate an exception.  See
L<VMware::vCloudDirector::API/PUT>.

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
