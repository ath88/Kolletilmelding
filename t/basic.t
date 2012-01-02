#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 14;
use Test::Mojo;

use Data::Dump qw(dump);


use_ok 'Kolle';
use_ok 'Kolle::Model';

use Kolle::Model;
Kolle::Model::_truncate();
#TODO

my $t = Test::Mojo->new('Kolle');
$t->get_ok('/')->content_like(qr/frontpage/i);
$t->get_ok('/day/monday')->content_like(qr/monday/i);
$t->get_ok('/day/tuesday')->content_like(qr/tuesday/i);
$t->get_ok('/day/friday')->content_like(qr/friday/i);

#$t->get_ok('/edit/1')->content_like(qr/unknown/i);


create_user('hans','christian','1','klan knold','blah@aths.dk');

my $user_ref = get_user('1');

ok($user_ref->{firstname} eq 'hans');
ok($user_ref->{lastname} eq 'christian');
ok($user_ref->{email} eq 'blah@aths.dk');

update_user('1',1,0,1,0,1,1);

$user_ref = get_user('1');

ok($user_ref->{day1} eq '1');

#$t->get_ok('/edit/1')->content_like(qr/hans/i);
