package VMware::vCloudDirector::API;

# ABSTRACT: Module to do stuff!

use strict;
use warnings;

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;
use MIME::Base64;
use MooseX::Types::Path::Tiny qw/Path/;
use Mozilla::CA;
use Path::Tiny;
use Ref::Util qw(is_plain_hashref);
use Scalar::Util qw(looks_like_number);
use Syntax::Keyword::Try;
use VMware::vCloudDirector::Error;
use VMware::vCloudDirector::Object;
use VMware::vCloudDirector::UA;
use XML::Fast qw();

# ------------------------------------------------------------------------
has hostname   => ( is => 'ro', isa => 'Str',  required => 1 );
has username   => ( is => 'ro', isa => 'Str',  required => 1 );
has password   => ( is => 'ro', isa => 'Str',  required => 1 );
has orgname    => ( is => 'ro', isa => 'Str',  required => 1, default => 'System' );
has ssl_verify => ( is => 'ro', isa => 'Bool', default  => 1 );
has debug      => ( is => 'rw', isa => 'Int',  default  => 0, );
has timeout => ( is => 'rw', isa => 'Int', default => 120 );    # Defaults to 120 seconds

has default_accept_header => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => '_build_default_accept_header',
    clearer => '_clear_default_accept_header',
);

has _base_url => (
    is      => 'ro',
    isa     => 'URI',
    lazy    => 1,
    builder => '_build_base_url',
    writer  => '_set_base_url',
    clearer => '_clear_base_url',
);

has ssl_ca_file => (
    is      => 'ro',
    isa     => Path,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_ssl_ca_file'
);

method _build_ssl_ca_file () { return path( Mozilla::CA::SSL_ca_file() ); }
method _build_base_url () { return URI->new( sprintf( 'https://%s/', $self->hostname ) ); }
method _build_default_accept_header () { return ( 'application/*+xml;version=' . $self->api_version ); }
method _debug (@parameters) { warn join( '', '# ', @parameters, "\n" ) if ( $self->debug ); }

# ------------------------------------------------------------------------

=head2 debug

Set debug level.  The higher the debug level, the more chatter is exposed.

Defaults to 0 (no output) unless the environment variable C<VCLOUD_API_DEBUG>
is set to something that is non-zero.  Picked up at create time in C<BUILD()>

=cut

method BUILD ($args) {

    # deal with setting debug if needed
    my $env_debug = $ENV{VCLOUD_API_DEBUG};
    if ( defined($env_debug) ) {
        $self->debug($env_debug) if ( looks_like_number($env_debug) );
    }
}

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
method _decode_xml_response ($response) {
    try {
        my $xml = $response->decoded_content;
        return unless ( defined($xml) and length($xml) );
        return XML::Fast::xml2hash($xml);
    }
    catch {
        VMware::vCloudDirector::Error->throw(
            {   message  => "XML decode failed - " . join( ' ', $@ ),
                response => $response
            }
        );
    }
}

# ------------------------------------------------------------------------
method _encode_xml_content ($hash) {
    return XML::Hash::XS::hash2xml( $hash, method => 'LX' );
}

# ------------------------------------------------------------------------
method _request ($method, $url, $content?, $headers?) {
    my $uri = URI->new_abs( $url, $self->_base_url );
    $self->_debug("API: _request [$method] $uri") if ( $self->debug );

    my $request = HTTP::Request->new( $method => $uri );

    # build headers
    if ( defined $content && length($content) ) {
        $request->content($content);
        $request->header( 'Content-Length', length($content) );
    }
    else {
        $request->header( 'Content-Length', 0 );
    }

    # add any supplied headers
    my $seen_accept;
    if ( defined($headers) ) {
        foreach my $h_name ( keys %{$headers} ) {
            $request->header( $h_name, $headers->{$h_name} );
            $seen_accept = 1 if ( lc($h_name) eq 'accept' );
        }
    }

    # set accept header
    $request->header( 'Accept', $self->default_accept_header ) unless ($seen_accept);

    # set auth header
    $request->header( 'x-vcloud-authorization', $self->authorization_token )
        if ( $self->has_authorization_token );

    # do request
    my $response;
    try { $response = $self->_ua->request($request); }
    catch {
        VMware::vCloudDirector::Error->throw(
            {   message => "$method request bombed",
                uri     => $uri,
                request => $request,
            }
        );
    }

    # Throw if this went wrong
    if ( $response->is_error ) {
        VMware::vCloudDirector::Error->throw(
            {   message  => "$method request failed",
                uri      => $uri,
                request  => $request,
                response => $response
            }
        );
    }

    return $response;
}

# ------------------------------------------------------------------------

=head1 API SHORTHAND METHODS

=head2 api_version

* Relative URL: /api/versions

The C<api_version> holds the version number of the highest discovered non-
deprecated API, it is initialised by connecting to the C</api/versions>
endpoint, and is called implicitly during the login setup.  Once filled the
values are cached.

=cut

has api_version => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    clearer => '_clear_api_version',
    builder => '_build_api_version'
);
has _url_login => (
    is      => 'rw',
    isa     => 'URI',
    lazy    => 1,
    clearer => '_clear_url_login',
    builder => '_build_url_login'
);
has _raw_version => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    clearer => '_clear_raw_version',
    builder => '_build_raw_version'
);
has _raw_version_full => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    clearer => '_clear_raw_version_full',
    builder => '_build_raw_version_full'
);

method _build_api_version ()  { return $self->_raw_version->{Version}; }
method _build_url_login () { return URI->new( $self->_raw_version->{LoginUrl} ); }

method _build_raw_version () {
    my $hash    = $self->_raw_version_full;
    my $version = 0;
    my $version_block;
    for my $verblock ( @{ $hash->{SupportedVersions}{VersionInfo} } ) {
        next unless ( $verblock->{-deprecated} eq 'false' );
        if ( $verblock->{Version} > $version ) {
            $version_block = $verblock;
            $version       = $verblock->{Version};
        }
    }

    $self->_debug("API: version used: $version") if ( $self->debug );
    die "No valid version block seen" unless ($version_block);

    return $version_block;
}

method _build_raw_version_full () {
    my $response = $self->_request( 'GET', '/api/versions', undef, { Accept => 'text/xml' } );
    return $self->_decode_xml_response($response);
}

# ------------------------ ------------------------------------------------
has authorization_token => (
    is        => 'ro',
    isa       => 'Str',
    writer    => '_set_authorization_token',
    clearer   => '_clear_authorization_token',
    predicate => 'has_authorization_token'
);

has current_session => (
    is        => 'ro',
    isa       => 'VMware::vCloudDirector::Object',
    clearer   => '_clear_current_session',
    predicate => 'has_current_session',
    lazy      => 1,
    builder   => '_build_current_session'
);

method _build_current_session () {
    my $login_id = join( '@', $self->username, $self->orgname );
    my $encoded_auth = 'Basic ' . MIME::Base64::encode( join( ':', $login_id, $self->password ) );
    $self->_debug("API: attempting login as: $login_id") if ( $self->debug );
    my $response =
        $self->_request( 'POST', $self->_url_login, undef, { Authorization => $encoded_auth } );

    # if we got here then it succeeded, since we throw on failure
    my $token = $response->header('x-vcloud-authorization');
    $self->_set_authorization_token($token);
    $self->_debug("API: authentication token: $token") if ( $self->debug );

    # we also reset the base url to match the login URL
    ## $self->_set_base_url( $self->_url_login->clone->path('') );

    my ($session) = $self->_build_returned_objects($response);
    return $session;
}

method login () { return $self->current_session; }

method logout () {
    if ( $self->has_current_session ) {

        # just do this - it might fail, but little you can do now
        try { $self->DELETE( $self->_url_login ); }
        catch { warn "DELETE of session failed: ", @_; }
    }
    $self->_clear_api_data;
}

# ------------------------------------------------------------------------
method _build_returned_objects ($response) {

    if ( $response->is_success ) {
        $self->_debug("API: building objects") if ( $self->debug );

        my $hash = $self->_decode_xml_response($response);
        unless ( defined($hash) ) {
            $self->_debug("API: returned null object") if ( $self->debug );
            return;
        }

        # See if this is a list of things, in which case root element will
        # be ThingList and it will have a set of Thing in it
        my @top_keys   = keys %{$hash};
        my $top_key    = $top_keys[0];
        my $thing_type = substr( $top_key, 0, -4 );
        if (    ( scalar(@top_keys) == 1 )
            and ( substr( $top_key, -4, 4 ) eq 'List' )
            and is_plain_hashref( $hash->{$top_key} )
            and ( scalar( keys %{ $hash->{$top_key} } ) == 1 ) ) {
            my @thing_objects;
            $self->_debug("API: building a set of [$thing_type] objects") if ( $self->debug );
            foreach my $thing ( $self->_listify( $hash->{$top_key}{$thing_type} ) ) {
                push @thing_objects,
                    VMware::vCloudDirector::Object->new(
                    {   hash => { $thing_type => $thing },
                        api  => $self
                    }
                    );
            }
            return @thing_objects;
        }

        # was not a list of things, so just objectify the one thing here
        else {
            $self->_debug("API: building a single [$top_key] object") if ( $self->debug );
            return VMware::vCloudDirector::Object->new(
                {   hash => $hash,
                    api  => $self
                }
            );
        }
    }

    # there was an error here - so bomb out
    else {
        VMware::vCloudDirector::Error->throw(
            { message => 'Error reponse passed to object builder', response => $response } );
    }
}

# ------------------------------------------------------------------------
method GET ($url) {
    $self->current_session;    # ensure/force valid session in place
    my $response = $self->_request( 'GET', $url );
    return $self->_build_returned_objects($response);
}

method PUT ($url, $xml_hash) {
    $self->current_session;    # ensure/force valid session in place
    my $content = is_plain_hashref($xml_hash) ? $self->_encode_xml_content($xml_hash) : $xml_hash;
    my $response = $self->_request( 'PUT', $url );
    return $self->_build_returned_objects($response);
}

method POST ($url, $xml_hash) {
    $self->current_session;    # ensure/force valid session in place
    my $content = is_plain_hashref($xml_hash) ? $self->_encode_xml_content($xml_hash) : $xml_hash;
    my $response = $self->_request( 'POST', $url );
    return $self->_build_returned_objects($response);
}

method DELETE ($url) {
    $self->current_session;    # ensure/force valid session in place
    my $response = $self->_request( 'DELETE', $url );
    return $self->_build_returned_objects($response);
}

# ------------------------------------------------------------------------

=head2 _clear_api_data

Clears out all the API state data, including the current login state.  This is
not intended to be used from outside the module, and will completely trash the
current state requiring a new login.  The basic information passed at object
construction time is not deleted, so a new session could be created.

=cut

method _clear_api_data () {
    $self->_clear_default_accept_header;
    $self->_clear_base_url;
    $self->_clear_ua;
    $self->_clear_api_version;
    $self->_clear_url_login;
    $self->_clear_raw_version;
    $self->_clear_raw_version_full;
    $self->_clear_authorization_token;
    $self->_clear_current_session;
}

# ------------------------------------------------------------------------
method _listify ($thing) { !defined $thing ? () : ( ( ref $thing eq 'ARRAY' ) ? @{$thing} : $thing ) }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
