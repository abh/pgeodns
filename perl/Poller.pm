package Poller;
use strict;

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  %{$self->{params}} = @_;
  bless ($self, $class);
  return $self;
}

sub name {
  my $self = shift;
  ($self =~ m/Poller::(.*?)=/)[0];
}

sub data_file {
  my $self = shift;
  $self->{data_file} = $_[0] if $_[0];
  $self->{data_file} ? $self->{data_file} : "data/" . $self->name . ".data";
  
}

sub lb_list {
  my $self = shift;
  $self->{lb_list} = $_[0] if $_[0] && ref $_[0] eq "ARRAY";
  $self->{lb_list} ? @{$self->{lb_list}} : ();
}

1;
