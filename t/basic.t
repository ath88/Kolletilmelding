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

# does root yield frontpage?
$t->get_ok('/')->content_like(qr/frontpage/i);

# testing if days work
$t->get_ok('/day/monday',  'get monday'  )->content_like(qr/monday/i ,     'content monday');
$t->get_ok('/day/tuesday', 'get tuesday' )->content_like(qr/tuesday/i,     'content tuesday');
$t->get_ok('/day/friday',  'get friday'  )->content_like(qr/friday/i,      'content fridag');
$t->get_ok('/day/Mandag',  'get Mandag'  )->content_like(qr/mandag/i,      'content mandag');
$t->get_ok('/day/tirsdag', 'get tirsdag' )->content_like(qr/tirsdag/i,     'content tirsdag');
$t->get_ok('/day/loerdag', 'get loerdag' )->content_like(qr/oslash;rdag/i, "content oslash;rdag");

# trying to get nonexisting days
$t->get_ok('/day/taggg',   'get taggg'   )->status_is('302');
$t->get_ok('/day/blooday', 'get blooday' )->status_is('302');

# trying to edit nonexisting users
$t->get_ok('/edit/bogus',       'get bogus'       )->status_is('302'); #->content_like(qr/unknown/i, 'content bogus');
$t->get_ok('/edit/nonexisting', 'get nonexisting' )->status_is('302'); #->content_like(qr/unknown/i, 'content nonexisting');

# test if random users exists
ok( !get_user('togga') );
ok( !get_user('bogussa') );

my $key = create_user('hans','christian','1','klan knold','blah@aths.dk');
create_user('peter','christian','1','klan knold','blah@aths.dk');
create_user('tor','christian','1','klan knold','blah@aths.dk');
create_user('jens','christian','1','klan knold','blah@aths.dk');
create_user('birk','christian','1','klan knold','blah@aths.dk');
create_user('lars','christian','1','klan knold','blah@aths.dk');

ok( get_user($key) );

my $user_ref = get_user($key);

is($user_ref->{firstname}, 'hans');
is($user_ref->{lastname}, 'christian');
is($user_ref->{email}, 'blah@aths.dk', 'email');

update_user($key,1,0,1,0,0,1);
#update_user('2',1,0,1,0,1,1);
#update_user('3',1,1,0,1,1,1);
#update_user('4',1,0,1,0,0,0);
#update_user('5',1,0,1,1,1,0);
#update_user('6',1,1,1,0,1,1);

$user_ref = get_user($key);

ok($user_ref->{day1} eq '1', 'new day1 is bool true');

$t->get_ok("/edit/$key", 'get edit/key')->content_like(qr/hans/i, 'content edit/key');


done_testing();
