package VMware::vCloudDirector;

# ABSTRACT: Module to do stuff!

use strict;
use warnings;

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::Path::Tiny qw/Path/;
use Mozilla::CA;
use Path::Tiny;
use Ref::Util qw(is_plain_hashref);
use Smart::Comments;
use Syntax::Keyword::Try;
use VMware::vCloudDirector::Error;
use VMware::vCloudDirector::API;

# ------------------------------------------------------------------------

has hostname   => ( is => 'ro', isa => 'Str',  required => 1 );
has username   => ( is => 'ro', isa => 'Str',  required => 1 );
has password   => ( is => 'ro', isa => 'Str',  required => 1 );
has orgname    => ( is => 'ro', isa => 'Str',  required => 1, default => 'System' );
has ssl_verify => ( is => 'ro', isa => 'Bool', default  => 1 );
has debug   => ( is => 'rw', isa => 'Bool', default => 0 );      # Defaults to no debug info
has timeout => ( is => 'rw', isa => 'Int',  default => 120 );    # Defaults to 120 seconds

has ssl_ca_file => (
    is      => 'ro',
    isa     => Path,
    coerce  => 1,
    lazy    => 1,
    builder => '_build_ssl_ca_file'
);
method _build_ssl_ca_file () { return path( Mozilla::CA::SSL_ca_file() ); }

has api => (
    is      => 'ro',
    isa     => 'VMware::vCloudDirector::API',
    lazy    => 1,
    builder => '_build_api'
);

method _build_api () {
    return VMware::vCloudDirector::API->new(
        hostname    => $self->hostname,
        username    => $self->username,
        password    => $self->password,
        orgname     => $self->orgname,
        ssl_verify  => $self->ssl_verify,
        debug       => $self->debug,
        timeout     => $self->timeout,
        ssl_ca_file => $self->ssl_ca_file,
    );
}

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
