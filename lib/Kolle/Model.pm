package Kolle::Model;

use strict;
use warnings;
use utf8;

use base 'Exporter';
our @EXPORT = ('day_exists' ,'get_days', 'get_day', 'get_user', 'update_user', 'create_user');

use String::Random qw(random_string);
use DBI;

use Data::Dumper;
use Email::Sender::Simple qw(sendmail);
use MIME::Entity;
use Encode qw(encode);
use POSIX;

use Mojo::Base qw(Mojolicious);
use Mojo::Log;

my $app = new Mojolicious;
my $log = Mojo::Log->new;
my $dbh = DBI->connect('DBI:mysql:kolle', 'root', '') || die "Could not connect to database: $DBI::errstr";
$dbh->{'mysql_enable_utf8'} = 1;
$dbh->{'mysql_auto_reconnect'} = 1;

#TODO remove default-adress
my $baseurl = 'http://localhost/edit/';

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
  my ($key, $new) = @_;
  delete $new->{type};
  my @bools = qw( bogger day1 day2 day3 day4 day5 day6 );
  foreach my $key (@bools) {
    if (defined $new->{$key} && $new->{$key} eq 'on') {
      $new->{$key} = 1;
    }
    else {
      $new->{$key} = 0;
    }
  }

  my $old = get_user($key);
  delete $old->{clanname};
  delete $old->{id};
  delete $old->{userkey};
  delete $old->{role};
  my $diff = _getDiffFromHashes( $old, $new );
  $log->info( "Update, key = $key.\n$diff" ) if $diff;

  return $dbh->do('
    UPDATE user 
    SET firstname = ?, lastname = ?, phone = ?, email = ?, day1 = ?, day2 = ?, day3 = ?, day4 = ?, day5 = ?, day6 = ?, comment1 = ?, comment2 = ?, comment3 = ?, comment4 = ?, comment5 = ?, comment6 = ?
    WHERE userkey = ?
  ',undef, $new->{firstname}, $new->{lastname}, $new->{phone}, $new->{email}, $new->{day1}, $new->{day2}, $new->{day3}, $new->{day4}, $new->{day5}, $new->{day6}, $new->{comment1}, $new->{comment2}, $new->{comment3}, $new->{comment4}, $new->{comment5}, $new->{comment6}, $key);
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
  $email = getlogin() . '@localhost' unless $app->mode eq 'production';

  my $body = 
"Hej $firstname $lastname,\n\nDu er tilmeldt Mølleå Divisions Seniorkolleuge 2012. For at du kan deltage i bespisningen skal du fortælle hvornår du gerne vil spise med. Benyt derfor dette link til at tilmelde dig, og rette din tilmelding.\n\n$baseurl$random_string\n\nHvis du ikke er $firstname $lastname, så svar venligst på mailen, så vi kan fejlfinde på problemet.\n\nMed venlig hilsen\nMølleå Divisions Seniorkolleugeudvalg";

  my $mail = MIME::Entity->build(
    Type    => 'text/plain',
    Charset => "UTF-8",
    Encoding => 'quoted-printable',
    From    => encode('MIME-Header','Asbjørn <senior@moelleaa.dk>'),
    To      => encode('MIME-Header',"$firstname $lastname <$email>"),
    Subject => encode('MIME-Header',"Tilmelding til Divisionskolleugen"),
    Data    => encode('UTF-8',$body),
  );

  sendmail($mail);

  return $random_string;
}

sub _truncate {
  $dbh->do('
    truncate table user
  ');
}

sub _getDiffFromHashes {
  my ($hash1, $hash2) = @_;
  my $result;
  for my $key ( keys %{$hash1} ) {
    if ( !defined( $hash2->{$key} ) ) {
      $result .= "Key: $key = no longer used\n";
      next;
    }
    if ($hash1->{$key} ne $hash2->{$key}) {
      $result .= "Key: $key = [" . $hash1->{$key} . '] becomes [' . $hash2->{$key} . "]\n";
    }
  }
  for my $key ( keys %{$hash2} ) {
    if ( !defined( $hash1->{$key} ) ) {
      $result .= "[$key] is new\n";
    }
  }
  return $result;
}

1;
