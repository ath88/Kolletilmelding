package Kolle::Model;

use strict;
use warnings;
use utf8;

use base 'Exporter';
our @EXPORT = ('day_exists' ,'get_days', 'get_day', 'get_user', 'update_user', 'create_user', 'email_exists');

use String::Random qw(random_string);
use DBI;

use Data::Dumper;
use Email::Sender::Simple qw(sendmail);
use MIME::Entity;
use Encode qw(encode);
use POSIX;

use Mojo::Base qw(Mojolicious);
use Mojo::Log;

my $dbtype = 'sqlite';

my $dbs = { mysql  => {connect => 'DBI:mysql:kolle'     , user => 'root', pass => ''},
	    sqlite => {connect => 'dbi:SQLite:dbname=db', user => '',     pass => ''},
};


my $app = new Mojolicious;
my $log = Mojo::Log->new;
my $dbh = DBI->connect($dbs->{$dbtype}{connect},$dbs->{$dbtype}{user},$dbs->{$dbtype}{pass}) || die "Could not connect to database: $DBI::errstr";

if ($dbtype eq 'mysql') {
  $dbh->{'mysql_enable_utf8'} = 1;
  $dbh->{'mysql_auto_reconnect'} = 1;
}

if ($dbtype eq 'sqlite') {
  $dbh->{sqlite_unicode} = 1;
}

my $baseurl = 'http://kolleuge.toenhalv.dk/edit/';

my $days = { 
             Friday    =>  1, Fredag   =>  1,
             Saturday  =>  2, Loerdag  =>  2,
             Sunday    =>  3, Soendag  =>  3,
             Monday    =>  4, Mandag   =>  4,
             Tuesday   =>  5, Tirsdag  =>  5,
             Wednesday =>  6, Onsdag   =>  6,
             Thursday  =>  7, Torsdag  =>  7,
             Friday2   =>  8, Fredag2  =>  8,
             Saturday2 =>  9, Loerdag2 =>  9,
             Sunday2   => 10, Soendag2 => 10,
};

sub day_exists {
  my $weekday = shift;
  return 1 if exists $days->{$weekday};
}

sub get_days {
  my $array_ref = $dbh->selectall_arrayref('
    SELECT firstname, lastname, clanname, 
           day1, comment1, day2, comment2, day3, comment3, day4, comment4, day5, comment5, 
           day6, comment6, day7, comment7, day8, comment8, day9, comment9, day10, comment10, 
	   id, userkey
    FROM user
  ');

  return $array_ref;
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
  my ($key, $new, $ip) = @_;
  delete $new->{type};
  my @bools = qw( bogger day1 day2 day3 day4 day5 day6 day7 day8 day9 day10 );
  foreach my $key (@bools) {
    if (defined $new->{$key} && $new->{$key} eq 'on') {
      $new->{$key} = 1;
    }
    else {
      $new->{$key} = 0;
    }
  }

  my $old = get_user($key);
  my $id = $old->{id};
  delete $old->{clanname};
  delete $old->{id};
  delete $old->{userkey};
  delete $old->{role};
  my $diff = _getDiffFromHashes( $old, $new );
  $log->info( "User [$id] update, IP = [$ip]\n$diff" ) if $diff && defined $id && defined $ip;

  return 0 unless $diff;

  return $dbh->do('
    UPDATE user 
    SET firstname = ?, lastname = ?, phone = ?, email = ?, bogger = ?, 
        day1 = ?, day2 = ?, day3 = ?, day4 = ?, day5 = ?, day6 = ?, day7 = ?, day8 = ?, day9 = ?, day10 = ?,
        comment1 = ?, comment2 = ?, comment3 = ?, comment4 = ?, comment5 = ?, comment6 = ?, comment7 = ?, comment8 = ?, comment9 = ?, comment10 = ?
    WHERE userkey = ?
  ',undef, $new->{firstname}, $new->{lastname}, $new->{phone}, $new->{email}, $new->{bogger}, 
           $new->{day1}, $new->{day2}, $new->{day3}, $new->{day4}, $new->{day5}, 
           $new->{day6}, $new->{day7}, $new->{day8}, $new->{day9}, $new->{day10}, 
           $new->{comment1} || '', $new->{comment2} || '', $new->{comment3} || '', $new->{comment4} || '', $new->{comment5}  || '', 
           $new->{comment6} || '', $new->{comment7} || '', $new->{comment8} || '', $new->{comment9} || '', $new->{comment10} || '', 
    $key);
}

sub create_user {
  my ($firstname, $lastname, $role, $clanname, $email, $id, $ip) = @_;

  # generate random string, and check if it already exists (really lucky if it does, though!)
  my $random_string;
  do { $random_string = random_string('c'x60) } while ( get_user( $random_string ) );

  #create empty user
  $dbh->do('
    INSERT INTO user (firstname, lastname, role, clanname, email, userkey)
    VALUES (?, ?, ?, ?, ?, ?)
  ', undef, $firstname, $lastname, $role, $clanname, $email, $random_string);
  $log->info("User [$id] created user, IP = [$ip]\nFirstname: [$firstname]\nLastname: [$lastname]\nClanname: [$clanname]\nEmail: [$email]" ) if defined $id && defined $ip;

  #send mail to user
  #$email =' ath88@localhost'; 
  $email = getlogin() . '@localhost' unless $app->mode eq 'production';

  my $name = $firstname;
  $name .= " $lastname" if $lastname;

  my $body = 
"Hej $name,\n\nKlan 2½'s Kolleuge er nær!!\nFor at du kan deltage i bespisningen skal du fortælle hvornår du gerne vil spise med. Benyt derfor dette personlige link til at tilmelde dig, og rette din tilmelding.\n\n$baseurl$random_string\n\nHvis du ikke er $name, så svar venligst på mailen, så vi kan fejlfinde på problemet.\n\nMed venlig hilsen\nAsbjørn på vejne af Kolleugeudvalget";

  my $mail = MIME::Entity->build(
    Type    => 'text/plain',
    Charset => "UTF-8",
    Encoding => 'quoted-printable',
    From    => encode('MIME-Header','Asbjørn <asbjoern@toenhalv.dk>'),
    To      => encode('MIME-Header',"$name <$email>"),
    Subject => encode('MIME-Header',"Tilmelding til Klan 2½'s Kolleuge"),
    Data    => encode('UTF-8',$body),
  );

  eval { sendmail($mail) };
  if ($@) {
    $log->warn("Email not sent:\n$@");
  }
  else {
    $log->info("Email sent to [$email]");
  }

  return $random_string;
}

sub email_exists {
  my $email = shift;
  my $id    = shift || undef;

  my @array;
  if (defined $id) {
    @array = $dbh->selectrow_array('
      SELECT id, email
      FROM user
      WHERE email = ? and id != ? 
    ', undef, $email, $id);
  }
  else {
    @array = $dbh->selectrow_array('
      SELECT id, email
      FROM user
      WHERE email = ? 
    ', undef, $email);
  }

  return @array;
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
      $result .= "[$key] no longer used\n";
      next;
    }
    if ($hash1->{$key} ne $hash2->{$key}) {
      $result .= "[$key] was [" . $hash1->{$key} . '], becomes [' . $hash2->{$key} . "]\n";
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
