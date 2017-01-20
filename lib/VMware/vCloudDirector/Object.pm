package VMware::vCloudDirector::Object;

# ABSTRACT: Module to do stuff!

use strict;
use warnings;

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::URI qw(Uri);
use Ref::Util qw(is_plain_hashref);
use VMware::vCloudDirector::Link;
use VMware::vCloudDirector::Error;

# ------------------------------------------------------------------------

has api => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector::API',
    required      => 1,
    weak_ref      => 1,
    documentation => 'API we use'
);

has mime_type => ( is => 'ro', isa => 'Str', required => 1 );
has href => ( is => 'ro', isa => Uri, required => 1, coerce => 1 );
has type => ( is => 'ro', isa => 'Str',     required  => 1 );
has hash => ( is => 'ro', isa => 'HashRef', required  => 1 );
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
    push( @links, VMware::vCloudDirector::Link->new( hash => $_, object => $self ) )
        foreach ( $self->_listify( $self->hash->{Link} ) );
    return \@links;
}

# ------------------------------------------------------------------------
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $params = is_plain_hashref( $_[0] ) ? $_[0] : {@_};

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
        $params->{id}        = $hash->{-id}   if ( exists( $hash->{-id} ) );
        $params->{mime_type} = $hash->{-type} if ( exists( $hash->{-type} ) );
    }

    return $class->$orig($params);
};

# ------------------------------------------------------------------------
method _listify ($thing) { !defined $thing ? () : ( ( ref $thing eq 'ARRAY' ) ? @{$thing} : $thing ) }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
