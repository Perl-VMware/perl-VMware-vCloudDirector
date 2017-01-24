package VMware::vCloudDirector::ObjectContent;

# ABSTRACT: A vCloud Object content

use strict;
use warnings;

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::URI qw(Uri);
use Ref::Util qw(is_plain_hashref);
use UUID::Tiny 1.02 qw(:std);
use VMware::vCloudDirector::Link;

# ------------------------------------------------------------------------

has object => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector::Object',
    required      => 1,
    weak_ref      => 1,
    documentation => 'Parent object'
);

has mime_type => ( is => 'ro', isa => 'Str', required => 1 );
has href => ( is => 'ro', isa => Uri, required => 1, coerce => 1 );
has type => ( is => 'ro', isa => 'Str',     required  => 1 );
has hash => ( is => 'ro', isa => 'HashRef', required  => 1, writer => '_set_hash' );
has name => ( is => 'ro', isa => 'Str',     predicate => 'has_name' );
has id   => ( is => 'ro', isa => 'Str',     predicate => 'has_id' );

# ------------------------------------------------------------------------

has links => (
    is      => 'ro',
    isa     => 'ArrayRef[VMware::vCloudDirector::Link]',
    lazy    => 1,
    builder => '_build_links'
);

method _build_links () {
    my @links;
    push( @links, VMware::vCloudDirector::Link->new( hash => $_, object => $self->object ) )
        foreach ( $self->_listify( $self->hash->{Link} ) );
    return \@links;
}

# ------------------------------------------------------------------------

=head2 find_link

Returns the first link found that matches the search criteria

=cut

method find_link (:$name, :$type, :$rel) {
    foreach my $link ( @{ $self->links } ) {
        if ( not( defined($rel) ) or ( $rel eq ( $link->rel || '' ) ) ) {
            if ( not( defined($type) ) or ( $type eq ( $link->type || '' ) ) ) {
                if ( not( defined($name) ) or ( $name eq ( $link->name || '' ) ) ) {
                    return $link;
                }
            }
        }
    }
}

# ------------------------------------------------------------------------
around BUILDARGS => sub {
    my ( $orig, $class, $first, @rest ) = @_;

    my $params = is_plain_hashref($first) ? $first : { $first, @rest };
    if ( $params->{hash} ) {
        my $top_hash = $params->{hash};

        my $hash;
        if ( scalar( keys %{$top_hash} ) == 1 ) {
            my $type = ( keys %{$top_hash} )[0];
            $hash           = $top_hash->{$type};
            $params->{type} = $type;
            $params->{hash} = $hash;
        }
        else {
            $hash = $top_hash;
        }

        $params->{href}      = $hash->{-href} if ( exists( $hash->{-href} ) );
        $params->{rel}       = $hash->{-rel}  if ( exists( $hash->{-rel} ) );
        $params->{name}      = $hash->{-name} if ( exists( $hash->{-name} ) );
        $params->{mime_type} = $hash->{-type} if ( exists( $hash->{-type} ) );
        if ( exists( $hash->{-id} ) ) {
            $params->{id} = $hash->{-id};
        }
        else {
            if ( defined( $params->{href} ) ) {
                my $id = substr( $params->{href}, -36 );
                $params->{id} = $id if ( is_uuid_string($id) );
            }
        }
    }

    return $class->$orig($params);
};

# ------------------------------------------------------------------------
method _listify ($thing) { !defined $thing ? () : ( ( ref $thing eq 'ARRAY' ) ? @{$thing} : $thing ) }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
