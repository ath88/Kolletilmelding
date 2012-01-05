package Kolle::Model;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = ('day_exists' ,'get_days', 'get_day', 'get_user', 'update_user', 'create_user');

use DBI;

my $dbh = DBI->connect('DBI:mysql:kolle', 'root', '') || die "Could not connect to database: $DBI::errstr";

my $days = { Monday    => 1, Mandag  => 1,
             Tuesday   => 2, Tirsdag => 2,
             Wednesday => 3, Onsdag  => 3,
             Thursday  => 4, Torsdag => 4,
             Friday    => 5, Fredag  => 5,
             Saturday  => 6, Loerdag => 6,
};

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
  my ($day) = @_;

  my $weekday = $days->{$day};

  my $sth = $dbh->prepare("
    SELECT firstname, lastname, clanname 
    FROM user 
    WHERE day$weekday = 1
  ");
  
  $sth->execute();

  my $array_ref = $sth->fetchall_arrayref;
  
  return $array_ref;
  

  return { name  => 'be late', 
           name2 => undef };
}

sub get_user {
  my ($id) = @_;

  my $result_ref = $dbh->selectrow_hashref('
    SELECT * 
    FROM user
    WHERE id = ?
  ',undef,$id);

  return $result_ref;
}

sub update_user {
  my ($id, $day1, $day2, $day3, $day4, $day5, $day6) = @_;

  $dbh->do('
    UPDATE user 
    SET day1 = ?, day2 = ?, day3 = ?, day4 = ?, day5 = ?, day6 = ?
    WHERE id = ?
  ',undef, $day1, $day2, $day3, $day4, $day5, $day6, $id);

  return 1;
}

sub create_user {
  my ($firstname, $lastname, $role, $clanname, $email) = @_;

  #create empty user
  $dbh->do('
    INSERT INTO user (firstname, lastname, role, clanname, email, day1, day2, day3, day4, day5, day6)
    VALUES (?, ?, ?, ?, ?, 0, 0, 0, 0, 0, 0)
  ', undef, $firstname, $lastname, $role, $clanname, $email);

  #send mail to user
  #TODO

  return 1;
}

sub _truncate {
  $dbh->do('
    truncate table user
  ');
}

1;
