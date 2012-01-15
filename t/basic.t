#!/usr/bin/env perl
use Mojo::Base -strict;
use utf8;

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

my $key1 = create_user('Mikkel',   'Rank',            '1','Tuliklan',  'blah@aths.dk');
my $key2 = create_user('Louise',   'Jacobsen',        '1','Skråklan', 'blah@aths.dk');
my $key3 = create_user('Laura',    'Katrine Engbaek', '2','Klan 2½',  'blah@aths.dk'); 
my $key4 = create_user("Asbjørn",  'Thegler',         '0','Klan 2½',  'blah@aths.dk');
my $key5 = create_user('Jeppe',    'Justesen',        '1','Bonanza',  'blah@aths.dk');
my $key6 = create_user('Frederik', 'Klein-Nielsen',   '2','Skråklan', 'blah@aths.dk');
my $key7 = create_user('Hans',     'Efternavn',       '2','Klan X',   'blah@aths.dk');
my $key8 = create_user('Peter',    'Efternavn',       '2','Klan X',   'blah@aths.dk');

ok( get_user($key1) );

my $user_ref = get_user($key1);

is($user_ref->{firstname}, 'Mikkel');
is($user_ref->{lastname}, 'Rank');
is($user_ref->{email}, 'blah@aths.dk', 'email');

update_user($key1,1,0,1,0,1,1,'','','Kommer senere','','','');
update_user($key2,0,0,0,0,1,0,'','','','','','');
update_user($key3,1,0,1,0,0,1,'Vil gerne undgå at spise med alligevel','','','','','');
update_user($key4,1,1,1,1,1,1,'','','','Tager snøfler med','','');
update_user($key5,1,0,0,1,0,0,'','','','','','');
update_user($key6,0,1,0,1,1,1,'','','','','','');
update_user($key7,1,0,0,1,1,1,'Tager en gæst med?','','','','kommer ikke til festen','');
update_user($key8,1,1,0,1,1,1,'','','','','','');

$user_ref = get_user($key1);

ok($user_ref->{day1} eq '1', 'new day1 is bool true');

$t->get_ok("/edit/$key1", 'get edit/key')->content_like(qr/Mikkel/i, 'content edit/key');


done_testing();
