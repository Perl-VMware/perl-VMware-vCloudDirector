package VMware::vCloudDirector::UA;

# ABSTRACT: Module to do stuff!

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use Method::Signatures;
use MooseX::Types::Path::Tiny qw/Path Paths AbsPath/;
use Mozilla::CA;
use LWP::UserAgent;

# ------------------------------------------------------------------------
has ssl_verify => ( is => 'ro', isa => 'Bool', default => 1 );
has ssl_ca_file => ( is => 'ro', isa => Path, lazy => 1, builder => '_build_ssl_ca_file' );
has timeout => ( is => 'rw', isa => 'Int', default => 120 );    # Defaults to 120 seconds
has _ua_module_version => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { our $VERSION //= '0.00'; sprintf( '%s/%s', __PACKAGE__, $VERSION ) }
);

method _build_ssl_ca_file () {
    return Mozilla::CA::SSL_ca_file();
}

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
        'request',             'simple_request',
        'ssl_opts'
    ]
);

method _build_ua () {
    return LWP::UserAgent->new(
        agent      => $self->_ua_module_version . ' ',
        cookie_jar => {},
        ssl_opts   => { verify_hostname => $self->ssl_verify, SSL_ca_file => $self->ssl_ca_file },
        timeout    => $self->timeout
    );
}

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloudDirector::UA - Module to do stuff!

=head1 VERSION

version 0.003

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
