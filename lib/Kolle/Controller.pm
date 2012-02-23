package Kolle::Controller;

use strict;
use warnings;
use utf8;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Log;
use Kolle::Model;

use HTML::Entities qw(encode_entities);
use Email::Valid;
use Validate::Tiny qw(validate);
use String::CamelCase qw(camelize);
use Data::Dumper qw(Dumper);
$Data::Dumper::Useperl = 1; # For proper dump of UTF-8 characters

my $log = Mojo::Log->new; 
my $app = new Mojolicious;
my $title = "Mølleå Divisions Seniorkolleuge";
my $debugmode = 0;

$debugmode = 1 if $app->mode eq 'development';
$log->level('info') if $app->mode ne 'development';
$log->info("MOJO_MODE is @{ [ $app->mode ] }");


sub frontpage {
  $log->debug("Viewing frontpage");
  my $self = shift;

  my $data = get_days();

  my ($totals, @empty);
  for my $i (0..$#{$data}) {
    $totals->{day1}++ if $data->[$i]->[3];
    $totals->{day2}++ if $data->[$i]->[5];
    $totals->{day3}++ if $data->[$i]->[7];
    $totals->{day4}++ if $data->[$i]->[9];
    $totals->{day5}++ if $data->[$i]->[11];
    $totals->{day6}++ if $data->[$i]->[13];

    my $good = 0;
    foreach my $day (@{$data->[$i]}[3,5,7,9,11,13]) {
      if ($day == 1) {
        $good = 1;
        last; 
      }
    }
    unshift(@empty, $i) if !$good;
  }

  splice( @{$data}, $_, 1) foreach @empty;


  my $success;
  my $error = $self->session->{'error'};
  delete $self->session->{'error'};
  return $self->render ( _build_response($data, $error, $success, $totals) );
}

sub day {
  my $self = shift;
  my $weekday = $self->stash('weekday');
  $weekday = camelize($weekday);
  if ( !day_exists($weekday) ) {
    $log->warn("Day unknown '$weekday'");
    $self->session->{'error'} = "Unknown weekday";
    return $self->redirect_to ('/');
  }


  $log->debug("Viewing day '$weekday'");

  my $data = get_day($weekday);

  $weekday =~ s/oe/ø/;

  my $success;
  my $error;
  return $self->render ( _build_response($data, $error, $success, {day => $weekday, total => ($#{$data}+1)} ) );
}

sub postedit {
  my $self = shift;
  my $key = $self->stash('key');

  my $data = get_user($key);
  if ( !$data ) {
    $self->session->{'error'} = "Don't do that, mkay?";
    return $self->redirect_to ('/');
  }

  $log->debug("Viewing postedit");

  my $request = $self->req;
  my ($error, $success, $error_desc);

  if ($request->param('type') eq 'input') {
    my $post = _postToHashref( $request );
    $post->{firstname} = camelize( $post->{firstname} );
    $post->{lastname}  = camelize( $post->{lastname} );
    $post->{phone}     =~ s/\s//g; 


    # validate data
    my %input = (
      firstname => $post->{firstname},
      lastname =>$post->{lastname},
      phone => $post->{phone},
      email => $post->{email},
      bogger => $post->{bogger},
    );

    my %rules = (
      fields => [ 'firstname', 'lastname', 'phone', 'email', 'bogger' ],
      checks => [
        [ qw/firstname lastname email/ ] => sub {
          my $value = shift;
          if ( !defined $value || $value eq '' ) {
            return "Feltet må ikke være tomt";
          }
          return undef;
        },
        firstname => \&valid_name,
        lastname => \&valid_name,
        phone => \&valid_phone,
        email => \&valid_email,
      ]
    );

    my $result = validate( \%input, \%rules );

    if ( email_exists( $post->{email} , $data->{id}) ) {
      $error = 1;
      $data->{error_msg}->{email} = 'E-mailen findes allerede';
    }

    # decide on result
    if ( $result->{success} && !$error) {
      my $role = ($data->{role} + 1);
      my $ok = update_user($key, $post, $self->tx->remote_address);

      if ( $ok ) {
        $success = 'Brugeren er opdateret';
        #get newest data
        $data = get_user($key);
      }
    } else {
      $data->{error} = 'input';
      $data->{error_msg} = { %{$data->{error_msg}}, %{$result->{error}} };
#      $data->{'firstname'} = $firstname;
#      $data->{'lastname'} = $lastname;
#      $data->{'phone'} = $phone;
#      $data->{'email'} = $email;
#      $data->{'bogger'} = $bogger;
      $error = 'Opdateringen mislykkedes';
    }
 
  }


  if ($request->param('type') eq 'new') {
    my $clanname = $request->param('new_clanname');
    my $firstname = camelize($request->param('new_firstname'));
    my $lastname = camelize($request->param('new_lastname'));
    my $email = $request->param('new_email');

    # can user create new user?
    if ($data->{role} == 2) {
      $error++; 
      $log->warn('ID [' . $data->{id} . ']: Forsøg på at invitere klanmedlem uden lederstatus');
    }
    if ($data->{role} == 1 && $clanname ne $data->{'clanname'}) {
      $error++; 
      $log->warn('ID [' . $data->{id} . ']: Forsøg på at invitere klanleder uden superlederstatus');
    }

    #TODO bruger med email eksisterer allerede
    
    # validate data
    my %input = (
      new_clanname => $clanname,
      new_firstname => $firstname,
      new_lastname => $lastname,
      new_email => $email,
    );

    my %rules = (
      fields => [ 'new_clanname', 'new_firstname', 'new_lastname', 'new_email' ],
      checks => [
        [ qw/new_clanname new_firstname new_email/ ] => sub {
          my $value = shift;
          if ( !defined $value || $value eq '' ) {
            return "Feltet må ikke være tomt";
          }
          return undef;
        },
        new_firstname => \&valid_name,
        new_lastname => \&valid_name,
        new_email => \&valid_email,
      ]
    );
    
    my $result = validate( \%input, \%rules );
 
    if ( email_exists( $email ) ) {
      $error = 1;
      $data->{error_msg}->{new_email} = 'E-mailen findes allerede';
    }

    # decide on result
    if ( $result->{success} && !$error) {
      my $role = ($data->{role} + 1);
      my $ok = create_user($firstname, $lastname, $role, $clanname, $email, $data->{id}, $self->tx->remote_address); 

      if ($ok ) {
        $success = 'Brugeren er oprettet og en email er sendt';
        $success .= " Ny nøgle: [$ok]" if $app->mode ne 'production';
      }      
    } else {
      $data->{error} = 'new';
      $data->{error_msg} = { %{$data->{error_msg}}, %{$result->{error}} };
      $data->{'new_clanname'} = $clanname;
      $data->{'new_firstname'} = $firstname;
      $data->{'new_lastname'} = $lastname;
      $data->{'new_email'} = $email;
      $error = 'Oprettelsen mislykkedes';
    }
  }
 
  return $self->render ( template => 'controller/edit', _build_response($data, $error, $success, $error_desc) );
}

sub edit {
  my $self = shift;
  my $key = $self->stash('key');
  $log->debug("Viewing edit");

  my $data = get_user($key);
  # check if user exists, return error if not
  if ( !$data ) {
    $self->session->{'error'} = "Unknown ID";
    return $self->redirect_to ('/');
  }

  my $success;

  my $error = $self->session->{'error'};
  delete $self->session->{'error'};
  return $self->render ( _build_response($data, $error, $success) );
}

sub dev {
  my $self = shift;
  $log->debug("Viewing dev");

  return $self->render_not_found if $app->mode eq 'production';
  
  my $data = get_days();
  my $error;
  my $success;

  return $self->render ( _build_response($data, $error, $success) );  
}

sub info {
  my $self = shift;
  $log->debug("Viewing info");

  my $data;
  my $error;
  my $success;

  return $self->render ( _build_response($data, $error, $success) );
}


###### non-route subroutines ######

sub _build_response {
  my ($data, $error, $success, $custom_ref) = @_;

  my %response;
  
  my $encoded_data = encode_struct( $data );
  
  $response{title}   = encode_entities($title);
  $response{error}   = encode_entities($error);
  $response{success} = encode_entities($success);
  $response{cont}    = $encoded_data;
  $response{debug}   = Dumper( $encoded_data )  if $debugmode;
  $response{mode}    = camelize( $app->mode ) unless $app->mode eq 'production';

  return %response unless defined $custom_ref;

  my %custom = %{$custom_ref};

  foreach my $key (keys %custom) {
    $custom{$key} = encode_struct( $custom{$key} );
  }

  return (%response, %custom);
}

sub encode_struct {
  my $struct = shift;
  my $result;

  if ( ref( $struct ) eq '') {
    $result = encode_entities( $struct );
  } 
  elsif ( ref( $struct ) eq 'ARRAY' ) {
    push( @{$result}, encode_struct( $_ ) ) for @{$struct} ;
  } 
  elsif ( ref( $struct ) eq 'HASH' ) {
    ${$result}{$_} = encode_struct( ${$struct}{$_} ) for keys %$struct;
  } 
  
  return $result;
}

sub valid_name {
  my $name = shift;
  return 'Må ikke indeholde tal' if $name =~ m/\d/;
  return undef;
}

sub valid_phone {
  my $phone = shift;
  return undef if $phone eq '';
  return 'Ugyldigt telefonnummer' unless $phone =~ m/^\d{8}$/;
  return undef;
}

sub valid_email {
  my $email = shift;
  return 'Ugyldig e-mail-adresse' unless Email::Valid->address( $email );
  return undef;
}

sub _postToHashref {
  my ($request) = @_;
  return {@{${$request->params}{params}}};
}

1;
