#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 11;
use Test::Mojo;

use Kolle::Model;

use_ok 'Kolle';
use_ok 'Kolle::Model';

my $t = Test::Mojo->new('Kolle');
$t->get_ok('/')->content_like(qr/frontpage/i);
$t->get_ok('/day/monday')->content_like(qr/monday/i);
$t->get_ok('/day/tuesday')->content_like(qr/tuesday/i);
$t->get_ok('/day/friday')->content_like(qr/friday/i);

#$t->get_ok('/edit/1')->content_like(qr/unknown/i);


create_user('hans','christian','1','klan knold','blah@aths.dk');

ok( get_user('1') );

#$t->get_ok('/edit/1')->content_like(qr/hans/i);
