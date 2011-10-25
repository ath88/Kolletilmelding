package Kolle;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

 # Tell Mojolicious we want to load the TT renderer plugin
  $self->plugin(tt_renderer => {
    template_options => {
      # These options are specific to TT
      INCLUDE_PATH => 'tmp',
      COMPILE_DIR => 'cache',
      COMPILE_EXT => '.ttc',
      # ... anything else to be passed on to TT should go here
    },
  });

  $self->renderer->default_handler('tt');


  # Routes
  my $r = $self->routes;

  # Normal route to controller
  $r->route('/')->to('controller#frontpage');
  $r->route('/day/:weekday')->to('controller#day');
  $r->route('/edit/:id')->via('POST')->to('controller#newedit');
  $r->route('/edit/:id')->to('controller#edit');
}

1;
