use strict;
use Test::More;
use Test::Exception;
use Test::LWP::UserAgent;
use FindBin;
use Path::Tiny;
use VMware::vCloudDirector;

FindBin->again;
my $datadir = path("$FindBin::Bin/data");

# fake useragent for testing
my $useragent = Test::LWP::UserAgent->new;
#
$useragent->map_response(
    qr{/api/versions},
    HTTP::Response->new(
        '200', HTTP::Status::status_message('200'),
        [ 'Content-Type' => 'text/xml' ], $datadir->child('api_versions_56.xml')->slurp
    ),
);

my @args = (
    hostname => 'vcloud.example.com',
    username => 'sysuser',
    password => 'syspass',
    orgname  => 'System',
    _ua      => $useragent
);

my $vcd = new_ok 'VMware::vCloudDirector' => \@args;
is( $vcd->api->api_version => '5.6', 'API version seen and is version 5.6' );

done_testing;
