package Kolle::Controller;

use strict;
use warnings;
use utf8;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Log;
use Kolle::Model;

use HTML::Entities qw(encode_entities);
use Email::Valid;
use String::CamelCase qw(camelize);
use Data::Dumper qw(Dumper);
$Data::Dumper::Useperl = 1; # For proper dump of UTF-8 characters

my $log = Mojo::Log->new; 
my $app = new Mojolicious;
my $title = "Mølleå Divisions Seniorkolleuge";
my $debugmode = 0;

$log->debug("MOJO_MODE is @{ [ $app->mode ] }");
$debugmode = 1 if ($app->mode eq 'development');


sub frontpage {
  $log->debug("Viewing frontpage");
  my $self = shift;


  my $data = get_days();

  my $success;
  my $error = $self->session->{'error'};
  delete $self->session->{'error'};
  return $self->render ( _build_response($data, $error, $success) );
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
    #validate update of user
    
    #update_user($user_iden, $postdata);
    $success = 'updated userdata';

    #get newest data
    $data = get_user($key);
  }


  if ($request->param('type') eq 'new') {
    my $clanname = $request->param('clanname');
    my $firstname = camelize($request->param('firstname'));
    my $lastname = camelize($request->param('lastname'));
    my $email = $request->param('email');

    #can user create new?
    if ($data->{role} == 2) {
      $error = 'Kun Klanledere kan invitere medlemmer, lad være med at snyde!';
      #TODO report
    }
    if ($data->{role} == 1 && $clanname ne $data->{'clanname'}) {
      $error = 'Kun SuperKlanledere kan invitere nye klaner. Stop det! :)';
      #TODO report
    }
    
    #validate create new user
    if (not valid_clanname($clanname)) {
      $data->{new_clanname_error} = 'Der skal være et klannavn.';
      $error = 'Fejl i oprettelse af ny bruger';
    }
    if (not valid_firstname($firstname)) {
      $data->{new_firstname_error} = 'Ikke et gyldigt navn.';
      $error = 'Fejl i oprettelse af ny bruger';
    }
    if (not valid_lastname($lastname)) {
      $data->{new_lastname_error} = 'Ikke et gyldigt efternavn.';
      $error = 'Fejl i oprettelse af ny bruger';
    }
    if (not valid_email($email)) {
      $data->{new_email_error} = 'Ikke en gyldig email-adresse.';
      $error = 'Fejl i oprettelse af ny bruger';
    }
    
    unless ($error) { 
      my $role = ($data->{role} + 1);
      my $ok = create_user($firstname, $lastname, $role, $clanname, $email); 

      if ($ok ) {
        $success = "created new user, email sent, $ok";
      } 

    }
    else {
      $data->{error} = 'new';
      $data->{'new_clanname'} = $clanname;
      $data->{'new_firstname'} = $firstname;
      $data->{'new_lastname'} = $lastname;
      $data->{'new_email'} = $email;
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

sub valid_clanname {
  my $name = shift;
  return 0 if $name eq '';
  return 1;
}
sub valid_firstname {
  my $name = shift;
  return 0 if $name eq '';
  return 0 if $name =~ m/\d/;
  return 1;
}
sub valid_lastname {
  my $name = shift;
  return 0 if $name =~ m/\d/;
  return 1;
}
sub valid_phone {
  my $phone = shift;
  return 1;
}
sub valid_email {
  my $email = shift;
  return 0 if $email eq '';
  return 0 unless Email::Valid->address($email);
  return 1;
}

1;
