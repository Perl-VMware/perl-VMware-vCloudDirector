package VMware::vCloudDirector::UA;

# ABSTRACT: Module to do stuff!

use strict;
use warnings;

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath/;
use Mozilla::CA;
use LWP::UserAgent;

# ------------------------------------------------------------------------
has ssl_verify => ( is => 'ro', isa => 'Bool', default => 1 );
has ssl_ca_file => ( is => 'ro', isa => 'Path', lazy => 1, builder => '_build_ssl_ca_file' );
has timeout => ( is => 'rw', isa => 'Int', default => 120 );    # Defaults to 120 seconds
has _ua_module_version => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { sprintf( '%s/%s', __PACKAGE__, $VERSION ) }
);

method _build_ssl_ca_file () { return Mozilla::CA::SSL_ca_file(); }

# ------------------------------------------------------------------------
has _ua => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    clearer => '_clear_ua',
    builder => '_build_ua',
    handles => [
        'default_header',      'credentials',
        'parse_head',          'protocols_allowed',
        'protocols_forbidden', 'requests_redirectable',
        'get',                 'head',
        'post',                'put',
        'request',             'simple_request'
    ]
);

method _build_ua () {
    return LWP::UserAgent->new(
        agent      => $self->_module_version . ' ',
        cookie_jar => {},
        timeout    => $self->timeout
    );
}

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
