package Kolle;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

 # Tell Mojolicious we want to load the TT renderer plugin
  $self->plugin(tt_renderer => {
    template_options => {
      # These options are specific to TT
      INCLUDE_PATH => "/home/ath88/work/Kolletilmelding/templates",
      COMPILE_DIR => '/tmp/cache',
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
  $r->route('/edit/:key')->via('POST')->to('controller#postedit');
  $r->route('/edit/:key')->to('controller#edit');
  $r->route('/dev')->to('controller#dev');
}

1;
