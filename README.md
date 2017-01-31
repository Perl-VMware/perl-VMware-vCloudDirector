# NAME

VMware::vCloudDirector - Interface to VMWare vCloud Directory REST API

# VERSION

version 0.004

## Attributes

### hostname

Hostname of the vCloud server.  Must have a vCloud instance listening for https
on port 443.

### username

Username to use to login to vCloud server.

### password

Password to use to login to vCloud server.

### orgname

Org name to use to login to vCloud server - this defaults to `System`.

### timeout

Command timeout in seconds.  Defaults to 120.

### default\_accept\_header

The default MIME types to accept.  This is automatically set based on the
information received back from the API versions.

### ssl\_verify

Whether to do standard SSL certificate verification.  Defaults to set.

### ssl\_ca\_file

The SSL CA set to trust packaged in a file.  This defaults to those set in the
[Mozilla::CA](https://metacpan.org/pod/Mozilla::CA)

## debug

Set debug level.  The higher the debug level, the more chatter is exposed.

Defaults to 0 (no output) unless the environment variable `VCLOUD_API_DEBUG`
is set to something that is non-zero.  Picked up at create time in `BUILD()`

# AUTHOR

Nigel Metheringham <nigelm@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
