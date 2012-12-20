use strict;
use warnings;

use RT::Test tests => undef;

my ($baseurl, $agent) = RT::Test->started_ok;

$agent->get("$baseurl/NoAuth/../Elements/HeaderJavascript");
is($agent->status, 400);
$agent->warning_like(qr/Invalid request.*aborting/);

$agent->get("$baseurl/NoAuth/../%45lements/HeaderJavascript");
is($agent->status, 400);
$agent->warning_like(qr/Invalid request.*aborting/);

$agent->get("$baseurl/NoAuth/%2E%2E/Elements/HeaderJavascript");
is($agent->status, 400);
$agent->warning_like(qr/Invalid request.*aborting/);

$agent->get("$baseurl/NoAuth/../../../etc/RT_Config.pm");
is($agent->status, 400);
$agent->warning_like(qr/Invalid request.*aborting/) unless $ENV{RT_TEST_WEB_HANDLER} =~ /^apache/;

$agent->get("$baseurl/static/css/web2/images/../../../../../../etc/RT_Config.pm");
# Apache hardcodes a 400m but the static handler returns a 403 for traversal too high
is($agent->status, $ENV{RT_TEST_WEB_HANDLER} =~ /^apache/ ? 400 : 403);

# do not reject these URLs, even though they contain /. outside the path
$agent->get("$baseurl/index.html?ignored=%2F%2E");
is($agent->status, 200);

$agent->get("$baseurl/index.html?ignored=/.");
is($agent->status, 200);

$agent->get("$baseurl/index.html#%2F%2E");
is($agent->status, 200);

$agent->get("$baseurl/index.html#/.");
is($agent->status, 200);

done_testing;
