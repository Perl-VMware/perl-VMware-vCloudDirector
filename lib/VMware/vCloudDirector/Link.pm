package VMware::vCloudDirector::Link;

# ABSTRACT: Link within the vCloud

use strict;
use warnings;

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::URI qw(Uri);
use Ref::Util qw(is_plain_hashref);
use VMware::vCloudDirector::Error;

# ------------------------------------------------------------------------

has object => (
    is            => 'ro',
    isa           => 'VMware::vCloudDirector::Object',
    required      => 1,
    weak_ref      => 1,
    documentation => 'Parent object of link'
);

has mime_type => ( is => 'ro', isa => 'Str', predicate => 'has_mime_type' );
has href => ( is => 'ro', isa => Uri, required => 1, coerce => 1 );
has rel  => ( is => 'ro', isa => 'Str', required  => 1 );
has name => ( is => 'ro', isa => 'Str', predicate => 'has_name' );
has type => ( is => 'ro', isa => 'Str', lazy      => 1, builder => '_build_type' );

method _build_type () {
    VMware::vCloudDirector::Error->throw("Type not set") unless ( $self->has_mime_type );

    my $type = $self->mime_type;
    if ( $type =~ m|^\Qapplication/vnd.vmware.vcloud.query.\E(.*)\Q+xml\E$| ) {
        return ( 'Query/' . $1 );
    }
    elsif ( $type =~ m|^\Qapplication/vnd.vmware.admin.\E(.*)\Q+xml\E$| ) {
        return ( 'Admin/' . $1 );
    }
    elsif ( $type =~ m|^\Qapplication/vnd.vmware.vcloud.\E(.*)\Q+xml\E$| ) {
        return ($1);
    }
    VMware::vCloudDirector::Error->throw("Type $type does not match expected pattern");
}

# ------------------------------------------------------------------------
around BUILDARGS => sub {
    my ( $orig, $class, $first, @rest ) = @_;

    my $params = is_plain_hashref($first) ? $first : { $first, @rest };

    if ( $params->{hash} ) {
        my $hash = delete $params->{hash};
        $params->{href}      = $hash->{-href} if ( exists( $hash->{-href} ) );
        $params->{rel}       = $hash->{-rel}  if ( exists( $hash->{-rel} ) );
        $params->{name}      = $hash->{-name} if ( exists( $hash->{-name} ) );
        $params->{mime_type} = $hash->{-type} if ( exists( $hash->{-type} ) );
    }

    return $class->$orig($params);
};

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
