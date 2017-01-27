package VMware::vCloudDirector;

# ABSTRACT: Interface to VMWare vCloud Directory REST API

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::Path::Tiny qw/Path/;
use Mozilla::CA;
use Path::Tiny;
use VMware::vCloudDirector::API;
use VMware::vCloudDirector::Error;
use VMware::vCloudDirector::Object;

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

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloudDirector - Interface to VMWare vCloud Directory REST API

=head1 VERSION

version 0.002

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
