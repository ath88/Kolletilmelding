package Kolle::Model;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = ('user_exists', 'day_exists' ,'get_days', 'get_day', 'get_user');

use DBI;

my $dbh = DBI->connect('DBI:mysql:kolle', 'root', '') || die "Could not connect to database: $DBI::errstr";

my $days = { monday    => 1, mandag  => 1,
             tuesday   => 2, tirsdag => 2,
             wednesday => 3, onsdag  => 3,
             thursday  => 4, torsdag => 4,
             friday    => 5, fredag  => 5,
             saturday  => 6, loerdag => 6,
};

sub user_exists {
  my $user = shift;
  return 1 if $user =~ m/123/;
}

sub day_exists {
  my $weekday = shift;
  return 1 if exists $days->{$weekday};
}

sub get_days {
  return { name  => [ monday    => 'be late', 
                      wednesday => undef, 
                      friday    => undef ], 
           name2 => [ friday    => undef ] };
}

sub get_day {
  return { name  => 'be late', 
           name2 => undef };
}

sub get_user {
  return { name => 'Mikkel', 
           rank => 'Klanleder', 
           days => {wednesday => undef, 
                    friday => 'be latez'} };
}

sub update_user {
  return 1;
}

sub create_user {

  #create empty user
  #send mail to user

  return 1;
}

1;
