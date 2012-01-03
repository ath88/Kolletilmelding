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

  return $self->render ( title => 'front', message => 'frontpage', dataset => $data );
}

sub day {
  my $self = shift;
  my $weekday = $self->stash('weekday');
  $log->debug("Viewing day '$weekday'");

  return $self->redirect_to ('/', error => "unknown weekday" ) if !day_exists($weekday);

  my $data => get_day($weekday);

  return $self->render ( message => $weekday, dataset => $data );
}

sub postedit {
  my $self = shift;
  my $user_iden = $self->stash('id');

  return $self->redirect_to ('/', error => "Don't do that, mkay?" ) if !user_exists($user_iden);
  $log->debug("Viewing postedit");

  my $postdata;
  #update_user($user_iden);
  

  return edit ( $self, $postdata);

  #$self->render ( message => 'postedit!');
}

sub edit {
  my $self = shift;
  my $user_iden = $self->stash('id');
  $log->debug("Viewing edit");

  # check if user exists, return error if not
  return $self->redirect_to ('/', error => "$user_iden doesnt exist" ) if !user_exists($user_iden);

  my $data => get_user($user_iden);

  return $self->render ( message => $user_iden, dataset => $data );
}

1;
