package VMware::vCloudDirector::API;

# ABSTRACT: Module to do stuff!

use strict;
use warnings;

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath/;
use Mozilla::CA;
use REST::Client;
use Smart::Comments;
use XML::Fast qw();
use VMware::vCloudDirector::UA;

# ------------------------------------------------------------------------
has hostname   => ( is => 'ro', isa => 'Str', required => 1 );
has username   => ( is => 'ro', isa => 'Str',  required => 1 );
has password   => ( is => 'ro', isa => 'Str',  required => 1 );
has orgname    => ( is => 'ro', isa => 'Str',  required => 1, default => 'System' );
has ssl_verify => ( is => 'ro', isa => 'Bool', default  => 1 );

has ssl_ca_file => (
    is      => 'ro',
    isa     => Path,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_ssl_ca_file'
);
has debug   => ( is => 'rw', isa => 'Int', default => 0 );      # Defaults to no debug info
has timeout => ( is => 'rw', isa => 'Int', default => 120 );    # Defaults to 120 seconds

has _base_url => ( is => 'ro', isa => 'URI', lazy => 1, builder => '_build_base_url' );

method _build_ssl_ca_file () { return Mozilla::CA::SSL_ca_file(); }
method _build_base_url () { return URI->new( sprintf( 'https://%s/', $self->hostname ) ); }

# ------------------------------------------------------------------------
has _ua => (
    is      => 'ro',
    isa     => 'VMware::vCloudDirector::UA',
    lazy    => 1,
    clearer => '_clear_ua',
    builder => '_build_ua'
);

method _build_ua () {
    return VMware::vCloudDirector::UA->new(
        ssl_verify  => $self->ssl_verify,
        ssl_ca_file => $self->ssl_ca_file,
        timeout     => $self->timeout,
    );
}

# ------------------------------------------------------------------------
method build_rest_client ($ua?) {
    ### Build new UA
    $ua ||= $self->_build_ua();

### Build new REST client
    my $client = REST::Client->new(
        host      => $self->_base_url,
        timeout   => $self->timeout,
        ca        => $self->ssl_ca_file,
        useragent => $ua
    );
}

# ------------------------------------------------------------------------
method _decode_xml_response ($client) {
    if ( $client->{_res}->is_success ) {
        return XML::Fast::xml2hash( $client->responseContent );
    }
    die "Request failed";
}

# ------------------------------------------------------------------------

=head1 API SHORTHAND METHODS

=head2 api_version

* Relative URL: /api/versions

This call queries the server for the current version of the API supported. It
is implicitly called when library is instanced.

=cut

has api_version => (is=>'ro',isa=>'Str',lazy=>1,clearer=>'_clear_api_version',builder=>'_build_api_version');
has _url_login => (is=>'rw',isa=>'URI',lazy=>1,clearer=>'_clear_url_login',builder=>'_build_url_login');
has _raw_version => (is=>'rw',isa=>'HashRef',lazy=>1,clearer=>'_clear_raw_version',builder=>'_build_raw_version');

method _build_api_version () { return $self->_raw_version->{Version}; }
method _build_url_login () { return URI->new( $self->_raw_version->{LoginUrl} ); }

method _build_raw_version () {
    my $client = $self->build_rest_client();
    ### GET /api/versions
    $client->GET('/api/versions');
    my $hash = $self->_decode_xml_response($client);

    my $version = 0;
    my $version_block;
    for my $verblock ( @{ $hash->{SupportedVersions}{VersionInfo} } ) {
        if ( $verblock->{Version} > $version ) {
            $version_block = $verblock;
            $version       = $verblock->{Version};
        }
    }

    ### vCloud API version seen $version
    die "No valid version block seen" unless ($version_block);

    return $version_block;
}

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
