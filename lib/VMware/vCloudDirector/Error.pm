package VMware::vCloudDirector::Error;

# ABSTRACT: Throw errors with the best of them

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;

extends 'Throwable::Error';

# ------------------------------------------------------------------------

has uri =>
    ( is => 'ro', isa => 'URI', documentation => 'An optional URI that was being processed' );

has response => ( is => 'ro', isa => 'Object', documentation => 'The response object' );
has request  => ( is => 'ro', isa => 'Object', documentation => 'The request object' );

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
