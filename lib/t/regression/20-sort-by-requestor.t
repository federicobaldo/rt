#!/usr/bin/perl -w
use strict; use warnings;

use Test::More qw/no_plan/;
use_ok('RT');
RT::LoadConfig();
RT::Init();
use RT::Ticket;

my $q = RT::Queue->new($RT::SystemUser);
my $queue = 'SearchTests-'.rand(200);
$q->Create(Name => $queue);

my @requestors = ( ('bravo@example.com') x 5, ('alpha@example.com') x 5,
                   ('delta@example.com') x 5, ('charlie@example.com') x 5);
my @subjects = ("first test", "second test", "third test", "fourth test") x 5;
while (@requestors) {
    my $t = RT::Ticket->new($RT::SystemUser);
    my ( $id, undef $msg ) = $t->Create(
        Queue      => $q->id,
        Subject    => shift @subjects,
        Requestor => [ shift @requestors ]
    );
    ok( $id, $msg );
}

{
    my $tix = RT::Tickets->new($RT::SystemUser);
    $tix->FromSQL("Queue = '$queue'");
    is($tix->Count, 20, "found twenty tickets");
}

{
    my $tix = RT::Tickets->new($RT::SystemUser);
    $tix->FromSQL("Queue = '$queue' AND requestor = 'alpha\@example.com'");
    $tix->OrderByCols({ FIELD => "Subject" });
    my @subjects;
    while (my $t = $tix->Next) { push @subjects, $t->Subject; }
    is(@subjects, 5, "found five tickets");
    is_deeply( \@subjects, [ sort @subjects ], "Subjects are sorted");
}

sub check_emails_order
{
    my ($tix,$count,$order) = (@_);
    my @mails;
    while (my $t = $tix->Next) { push @mails, $t->RequestorAddresses; }
    is(@mails, $count, "found $count tickets");
    my @required_order;
    if( $order =~ /asc/i ) {
        @required_order = sort { $a? ($b? ($a cmp $b) : -1) : 1} @mails;
    } else {
        @required_order = sort { $a? ($b? ($b cmp $a) : -1) : 1} @mails;
    }
    foreach( reverse splice @mails ) {
        if( $_ ) { unshift @mails, $_ }
        else { push @mails, $_ }
    }
    is_deeply( \@mails, \@required_order, "Addresses are sorted");
}

{
    my $tix = RT::Tickets->new($RT::SystemUser);
    $tix->FromSQL("Queue = '$queue' AND subject = 'first test' AND Requestor.EmailAddress LIKE 'example.com'");
    $tix->OrderByCols({ FIELD => "Requestor.EmailAddress" });
    check_emails_order($tix, 5, 'ASC');
    $tix->OrderByCols({ FIELD => "Requestor.EmailAddress", ORDER => 'DESC' });
    check_emails_order($tix, 5, 'DESC');
}

{
    my $tix = RT::Tickets->new($RT::SystemUser);
    $tix->FromSQL("Queue = '$queue' AND Subject = 'first test'");
    $tix->OrderByCols({ FIELD => "Requestor.EmailAddress" });
    check_emails_order($tix, 5, 'ASC');
    $tix->OrderByCols({ FIELD => "Requestor.EmailAddress", ORDER => 'DESC' });
    check_emails_order($tix, 5, 'DESC');
}


{
    # create ticket with empty requestor list
    my $t = RT::Ticket->new($RT::SystemUser);
    my ( $id, $msg ) = $t->Create(
        Queue      => $q->id,
        Subject    => "first test",
    );
    ok( $id, "ticket created" ) or diag( "error: $msg" );
    is( $t->RequestorAddresses, '', "requestor address is empty" );
}

{
    my $tix = RT::Tickets->new($RT::SystemUser);
    $tix->FromSQL("Queue = '$queue' AND Subject = 'first test'");
    $tix->OrderByCols({ FIELD => "Requestor.EmailAddress" });
    check_emails_order($tix, 6, 'ASC');
    $tix->OrderByCols({ FIELD => "Requestor.EmailAddress", ORDER => 'DESC' });
    check_emails_order($tix, 6, 'DESC');
}

{
    # create ticket with group as member of the requestors group
    my $t = RT::Ticket->new($RT::SystemUser);
    my ( $id, $msg ) = $t->Create(
        Queue      => $q->id,
        Subject    => "first test",
        Requestor  => 'badaboom@example.com',
    );
    ok( $id, "ticket created" ) or diag( "error: $msg" );

    my $g = RT::Group->new($RT::SystemUser);

    my ($gid);
    ($gid, $msg) = $g->CreateUserDefinedGroup(Name => '20-sort-by-requestor.t-'.rand(200));
    ok($gid, "created group") or diag("error: $msg");

    ($id, $msg) = $t->Requestors->AddMember( $gid );
    ok($id, "added group to requestors group") or diag("error: $msg");
}

    my $tix = RT::Tickets->new($RT::SystemUser);    
    $tix->FromSQL("Queue = '$queue' AND Subject = 'first test'");
TODO: {
    local $TODO = "if group has non users members we get wrong order";
    $tix->OrderByCols({ FIELD => "Requestor.EmailAddress" });
    check_emails_order($tix, 7, 'ASC');
}
    $tix->OrderByCols({ FIELD => "Requestor.EmailAddress", ORDER => 'DESC' });
    check_emails_order($tix, 7, 'DESC');

# vim:ft=perl:
