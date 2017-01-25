use strict;
use Test::More;
use Test::Exception;

use VMware::vCloudDirector;

# Check for connection info to run additonal tests
our %ENV;

my $host = $ENV{VCLOUD_SYSTEM_HOST};
my $user = $ENV{VCLOUD_SYSTEM_USER};
my $pass = $ENV{VCLOUD_SYSTEM_PASS};
my $org  = 'System';

unless ( $host and $user and $pass and $org ) {
    diag(
        "\n",
        "No host connection info found. Skipping additional tests.\n",
        "\n",
        "Set environment variables:\n",
        "    VCLOUD_SYSTEM_HOST, VCLOUD_SYSTEM_USER,\n",
        "    VCLOUD_SYSTEM_PASS\n",
        "to run full test suite.\n",
        "\n",
    );
    plan skip_all => "No vCloud connection Information";
}

subtest 'Connection test with correct parameters' => sub {
    my $vcd = new_ok 'VMware::vCloudDirector' => [
        hostname   => $host,
        username   => $user,
        password   => $pass,
        orgname    => $org,
        ssl_verify => 0,
    ];
    ok( ( $vcd->api->api_version > 1.0 ), 'API version seen and more than 1.0' );
    my $session;
    lives_ok( sub { $session = $vcd->api->login }, 'Login did not die' );
    isa_ok( $session, 'VMware::vCloudDirector::Object', 'Got an object back from login' );
    is( $session->type, 'Session', 'The object is a Session' );
    my $org_list = $vcd->org_list;
    is( ref($org_list), 'ARRAY', 'Org list is an array reference' );
    isa_ok( $org_list->[0], 'VMware::vCloudDirector::Object', 'Org list object is the right type' );
    is( $org_list->[0]->type, 'Org', 'Org list object is an Org object' );
    ok( ( scalar( @{$org_list} ) > 1 ), 'Org list has multiple entries (needed for System)' );
    my ($sysorg) = grep { $_->name eq 'System' } @{$org_list};
    ok( defined($sysorg), 'System org has been found' );
    isa_ok( $sysorg, 'VMware::vCloudDirector::Object', 'System org object is the right type' );
    is( $sysorg->type, 'Org', 'System org object is an Org object' );
    my @catlinks = $sysorg->find_links( rel => 'down', type => 'catalog' );
    ok( scalar(@catlinks), 'At least one catalog link has been found' );
    my $catlink = $catlinks[0];
    isa_ok( $catlink, 'VMware::vCloudDirector::Link', 'Link object is the right type' );
    my $catalog = [ $catlink->GET() ];
    ok( scalar( @{$catlink} ), 'At least one catalog item has been retrieved' );
    done_testing();
};

subtest 'Connection test with incorrect password' => sub {
    my $vcd = new_ok 'VMware::vCloudDirector' => [
        hostname   => $host,
        username   => $user,
        password   => 'this_is_an_incorrect_password',
        orgname    => $org,
        ssl_verify => 0,
    ];
    ok( ( $vcd->api->api_version > 1.0 ), 'API version seen and more than 1.0' );
    dies_ok( sub { $vcd->api->login }, 'Incorrect login throws an exception' );
    done_testing();
};

done_testing;
