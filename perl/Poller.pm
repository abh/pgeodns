package Poller;
use strict;
use LWP::Simple qw(RC_OK RC_NOT_MODIFIED);

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

sub mirror_url {
  my ($self, $url) = @_;
  my $file = $self->data_file;
  my $mirror_rv = LWP::Simple::mirror($url, $file);
  if ($mirror_rv == RC_NOT_MODIFIED) {
    return 0;
  }
  unless ($mirror_rv == RC_OK) {
    print "poller could not mirror datafile from $url to $file: $mirror_rv\n";
    return 0;
  }
  1;
}

1;
