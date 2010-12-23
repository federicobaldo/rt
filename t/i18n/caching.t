#!/usr/bin/perl -w
use strict;
use warnings;

use RT::Test;

{
    my $french = RT::User->new(RT->SystemUser);
    $french->LoadOrCreateByEmail('french@example.com');
    $french->SetName('french');
    $french->SetLang('fr');
    $french->SetPrivileged(1);
    $french->SetPassword('password');
    $french->PrincipalObj->GrantRight(Right => 'SuperUser');
}


my ($baseurl, $m) = RT::Test->started_ok;
$m->login( root => "password" );
$m->get_ok('/Prefs/Other.html');
$m->content_lacks('Commentaires','Lacks translated french');
$m->get_ok( "/NoAuth/Logout.html" );

$m->login( french => "password" );
$m->get_ok('/Prefs/Other.html');
$m->content_contains('Commentaires','Has translated french');
$m->get_ok( "/NoAuth/Logout.html" ); # ->logout fails because it's translated

$m->login( root => "password" );
$m->get_ok('/Prefs/Other.html');
{
    local $TODO = "Per-process caching bug";
    $m->content_lacks('Commentaires','Lacks translated french');
}

undef $m;