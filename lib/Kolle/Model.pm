package Kolle::Model;

use strict;
use warnings;
use utf8;

use base 'Exporter';
our @EXPORT = ('day_exists' ,'get_days', 'get_day', 'get_user', 'update_user', 'create_user');

use String::Random qw(random_string);
use DBI;

use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use MIME::Entity;
  

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
  my $result_ref = $dbh->selectall_arrayref('
    SELECT firstname, lastname, clanname, day1, comment1, day2, comment2, day3, comment3, day4, comment4, day5, comment5, day6, comment6
    FROM user
  ');

  return $result_ref;
}

sub get_day {
  my ($day) = @_;

  my $weekday = $days->{$day};

  my $sth = $dbh->prepare("
    SELECT firstname, lastname, clanname, comment$weekday 
    FROM user 
    WHERE day$weekday = 1
  ");
  
  $sth->execute();

  my $array_ref = $sth->fetchall_arrayref;
  
  return $array_ref;
}

sub get_user {
  my ($key) = @_;

  my $result_ref = $dbh->selectrow_hashref('
    SELECT * 
    FROM user
    WHERE userkey = ?
  ',undef,$key);

  return $result_ref;
}

sub update_user {
  my ($key, $day1, $day2, $day3, $day4, $day5, $day6, $comment1, $comment2, $comment3, $comment4, $comment5, $comment6) = @_;

  $dbh->do('
    UPDATE user 
    SET day1 = ?, day2 = ?, day3 = ?, day4 = ?, day5 = ?, day6 = ?, comment1 = ?, comment2 = ?, comment3 = ?, comment4 = ?, comment5 = ?, comment6 = ?
    WHERE userkey = ?
  ',undef, $day1, $day2, $day3, $day4, $day5, $day6, $comment1, $comment2, $comment3, $comment4, $comment5, $comment6, $key);

  return 1;
}

sub create_user {
  my ($firstname, $lastname, $role, $clanname, $email) = @_;

  # generate random string, and check if it already exists (really lucky if it does, though!)
  my $random_string;
  do { $random_string = random_string('c'x40) } while ( get_user( $random_string ) );

  #create empty user
  $dbh->do('
    INSERT INTO user (firstname, lastname, role, clanname, email, userkey)
    VALUES (?, ?, ?, ?, ?, ?)
  ', undef, $firstname, $lastname, $role, $clanname, $email, $random_string);

  #send mail to user

  #TODO remove default-adress
  $email = 'ath88@winters';

#  my $mail = MIME::Entity->build(
#    From    => '"Asbjoern" <senior@moelleaa.dk>',
#    To      => "\"$firstname $lastname\" <$email>",
#    Subject => "Tilmelding til Divisionskolleugen",
#    Data    => ["Her er dit link:\n", "http://localhost/edit/$random_string"]
#  );


  my $mail = Email::Simple->create(
    header => [
#      To      => "\"$firstname $lastname\" <$email>",
      To      => "<$email>",
      From    => '"Asbjoern" <senior@moelleaa.dk>',
      Subject => "Tilmelding til Divisionskolleugen",
    ],
    body => "Her er dit link:\n http://localhost/edit/$random_string",
  );

  sendmail($mail);

  return $random_string;
}

sub _truncate {
  $dbh->do('
    truncate table user
  ');
}

1;
