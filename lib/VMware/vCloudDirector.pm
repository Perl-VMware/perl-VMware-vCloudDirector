package VMware::vCloudDirector;

# ABSTRACT: Interface to VMWare vCloud Directory REST API

use strict;
use warnings;

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::Path::Tiny qw/Path/;
use Path::Tiny;
use VMware::vCloudDirector::API;
use VMware::vCloudDirector::Error;
use VMware::vCloudDirector::Object;

# ------------------------------------------------------------------------

has debug => ( is => 'rw', isa => 'Bool', default => 0 );    # Defaults to no debug info

has hostname   => ( is => 'ro', isa => 'Str',  required  => 1 );
has username   => ( is => 'ro', isa => 'Str',  required  => 1 );
has password   => ( is => 'ro', isa => 'Str',  required  => 1 );
has orgname    => ( is => 'ro', isa => 'Str',  required  => 1, default => 'System' );
has ssl_verify => ( is => 'ro', isa => 'Bool', predicate => '_has_ssl_verify' );
has timeout    => ( is => 'rw', isa => 'Int',  predicate => '_has_timeout' );
has ssl_ca_file => ( is => 'ro', isa => Path, coerce => 1, predicate => '_has_ssl_ca_file' );
has _ua => ( is => 'ro', isa => 'LWP::UserAgent', predicate => '_has_ua' );
has _debug_trace_directory =>
    ( is => 'ro', isa => Path, coerce => 1, predicate => '_has_debug_trace_directory' );

has api => (
    is      => 'ro',
    isa     => 'VMware::vCloudDirector::API',
    lazy    => 1,
    builder => '_build_api'
);

method _build_api () {
    my @args = (
        hostname => $self->hostname,
        username => $self->username,
        password => $self->password,
        orgname  => $self->orgname,
        debug    => $self->debug
    );
    push( @args, timeout     => $self->timeout )     if ( $self->_has_timeout );
    push( @args, ssl_verify  => $self->ssl_verify )  if ( $self->_has_ssl_verify );
    push( @args, ssl_ca_file => $self->ssl_ca_file ) if ( $self->_has_ssl_ca_file );
    push( @args, _debug_trace_directory => $self->_debug_trace_directory )
        if ( $self->_has_debug_trace_directory );
    push( @args, _ua => $self->_ua ) if ( $self->_has_ua );

    return VMware::vCloudDirector::API->new(@args);
}

# ------------------------------------------------------------------------
has org_listref => (
    is      => 'ro',
    isa     => 'ArrayRef[VMware::vCloudDirector::Object]',
    lazy    => 1,
    builder => '_build_org_listref',
    traits  => ['Array'],
    handles => {
        org_list => 'elements',
        org_map  => 'map',
        org_grep => 'grep',
    },
);
method _build_org_listref { return [ $self->api->GET('/api/org/') ]; }

# ------------------------------------------------------------------------
method query (@args) {
    my $uri = $self->api->query_uri->clone;
    $uri->query_form(@args);
    return $self->api->GET($uri);
}

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
