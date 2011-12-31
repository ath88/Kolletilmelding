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

  return $self->render ( message => 'frontpage', dataset => $data );
}

sub day {
  my $self = shift;
  my $weekday = $self->stash('weekday');
  $log->debug("Viewing day '$weekday'");

  return $self->render ( message => "$weekday doesnt exist" ) if !day_exists($weekday);

  my $data => get_day($weekday);

  return $self->render ( message => $weekday, dataset => $data );
}

sub newedit {
  my $self = shift;
  my $user_iden = $self->stash('id');
  $log->debug("Viewing newedit");

  # check if user exists, return error if not
  return $self->render ( message => "$user_iden doesnt exist" ) if !user_exists($user_iden);

  return $self->render ( message => 'postedit!');
}

sub edit {
  my $self = shift;
  my $user_iden = $self->stash('id');
  $log->debug("Viewing edit");

  # check if user exists, return error if not
  return $self->render ( message => "$user_iden doesnt exist" ) if !user_exists($user_iden);

  my $data => get_user($user_iden);

  return $self->render ( message => $user_iden, dataset => $data );
}

1;
