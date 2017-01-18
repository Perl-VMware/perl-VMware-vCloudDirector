package VMware::vCloudDirector::Error;

# ABSTRACT: Throw errors with the best of them

use strict;
use warnings;

# VERSION
# AUTHORITY

use Moose;
use Method::Signatures;

extends 'Throwable::Error';

# ------------------------------------------------------------------------

has uri => (is=>'ro',isa=>'URI',documentation=>'An optional URI that was being processed');

has response => (is=>'ro',isa=>'Object',documentation=>'The response object');

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;
