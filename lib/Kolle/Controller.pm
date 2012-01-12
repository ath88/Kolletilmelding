package Kolle::Controller;

use strict;
use warnings;
use utf8;

use Mojo::Base 'Mojolicious::Controller';
use Kolle::Model;
use Mojo::Log;

use HTML::Entities qw(encode_entities);
use String::CamelCase qw(camelize);
use Data::Dumper qw(Dumper);
$Data::Dumper::Useperl = 1; # For proper dump of UTF-8 characters

my $log = Mojo::Log->new; 

my $title = "M&oslash;lle&aring; divisions seniorkolleuge";

my $debugmode = 0;

my $app = new Mojolicious;
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
  return $self->render ( _build_response($data, $error, $success, {day => $weekday} ) );
}

sub postedit {
  my $self = shift;
  my $key = $self->stash('key');

  if ( !get_user($key) ) {
    $self->session->{'error'} = "Don't do that, mkay?";
    return $self->redirect_to ('/');
  }

  $log->debug("Viewing postedit");

  my $postdata;
  #update_user($user_iden, $postdata);
  

  return edit ( $self, $postdata);
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
  
  $response{title}   = $title;
  $response{error}   = $error;
  $response{success} = $success;
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

1;
