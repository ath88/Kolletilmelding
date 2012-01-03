#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Data::Dump qw(dump);


use_ok 'Kolle';
use_ok 'Kolle::Model';

use Kolle::Model;
Kolle::Model::_truncate();
#TODO remove _truncate()

my $t = Test::Mojo->new('Kolle');
$t->get_ok('/')->content_like(qr/frontpage/i);
$t->get_ok('/day/monday')->content_like(qr/monday/i);
$t->get_ok('/day/tuesday')->content_like(qr/tuesday/i);
$t->get_ok('/day/friday')->content_like(qr/friday/i);

#$t->get_ok('/edit/1')->content_like(qr/unknown/i);

ok( !user_exists('1') );

create_user('hans','christian','1','klan knold','blah@aths.dk');
create_user('peter','christian','1','klan knold','blah@aths.dk');
create_user('tor','christian','1','klan knold','blah@aths.dk');
create_user('jens','christian','1','klan knold','blah@aths.dk');
create_user('birk','christian','1','klan knold','blah@aths.dk');
create_user('lars','christian','1','klan knold','blah@aths.dk');

ok( user_exists('1') );

my $user_ref = get_user('1');

is($user_ref->{firstname}, 'hans');
is($user_ref->{lastname}, 'christian');
is($user_ref->{email}, 'blah@aths.dk');

update_user('1',1,0,1,0,0,1);
update_user('2',1,0,1,0,1,1);
update_user('3',1,1,0,1,1,1);
update_user('4',1,0,1,0,0,0);
update_user('5',1,0,1,1,1,0);
update_user('6',1,1,1,0,1,1);

$user_ref = get_user('1');

ok($user_ref->{day1} eq '1');

#$t->get_ok('/edit/1')->content_like(qr/hans/i);


done_testing();
