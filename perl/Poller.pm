package Poller;
use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  
  %{$self->{params}} = @_;

  bless ($self, $class);
  $self->initialize;
  return $self;
}

1;
