package Kolle::Controller;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use Kolle::Model;
use Mojo::Log;

use Data::Dump qw(dump);
use String::CamelCase qw(camelize);

my $log = Mojo::Log->new; 

my $title = "M&oslash;lle&aring; divisions seniorkolleuge";

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



  $weekday =~ s/oe/&oslash;/;

  my $success;
  my $error;
  return $self->render ( day => $weekday, _build_response($data, $error, $success) );
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


sub _build_response {
  my ($debug, $error, $success) = @_;

  my %response;
  
  $response{title}   = $title;
  $response{error}   = $error;
  $response{success} = $success;
  $response{debug}   = dump( $debug ) if $debug;

  return %response;
}

1;
