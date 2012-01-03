package Kolle::Controller;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use Kolle::Model;
use Mojo::Log;

my $log = Mojo::Log->new; 

sub frontpage {
  $log->debug("Viewing frontpage");
  my $self = shift;


  my $data = get_days();

  my $error = $self->session->{'error'};
  delete $self->session->{'error'};
  return $self->render ( title => 'front', error => $error, dataset => $data );
}

sub day {
  my $self = shift;
  my $weekday = $self->stash('weekday');
  if ( !day_exists($weekday) ) {
    $log->warn("Day unknown '$weekday'");
    $self->session->{'error'} = "Unknown weekday";
    return $self->redirect_to ('/');
  }
  $log->debug("Viewing day '$weekday'");

  my $data => get_day($weekday);

  return $self->render ( day => $weekday, dataset => $data );
}

sub postedit {
  my $self = shift;
  my $user_iden = $self->stash('id');

  if ( !user_exists($user_iden) ) {
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
  my $user_iden = $self->stash('id');
  $log->debug("Viewing edit");

  # check if user exists, return error if not
  if ( !user_exists($user_iden) ) {
    $self->session->{'error'} = "Unknown ID";
    return $self->redirect_to ('/');
  }


  my $data => get_user($user_iden);

  my $error = $self->session->{'error'};
  delete $self->session->{'error'};
  return $self->render ( message => $user_iden, error => $error, dataset => $data );
}

1;
