
package Mojo::IOLoop::LineReader;

# ABSTRACT: Non-blocking line-oriented input stream

use Mojo::Base 'Mojo::IOLoop::Stream';

use Scalar::Util ();

has 'input_record_separator';

sub new {
  my $self = shift->SUPER::new(@_);
  $self->{chunk} = '';
  $self->input_record_separator($/);
  return $self->_setup;
}

sub _setup {
  my $self = shift;

  Scalar::Util::weaken($self);
  $self->on(close => sub { shift; $self->_closeln(@_) });
  $self->on(read  => sub { shift; $self->_readln(@_) });

  return $self;
}

sub _closeln {
  my ($self) = @_;
  $self->emit(readln => $self->{chunk}) if length $self->{chunk};
  $self->{chunk} = '';
}

sub _readln {
  my ($self, $bytes) = @_;

  open my $r, '<', \$bytes;
  my $n;
  local $/ = $self->input_record_separator;
  while (<$r>) {
    unless (defined $n) {
      $n = $self->{chunk} . $_;
      next;
    }
    $self->emit(readln => $n);
    $n = $_;
  }
  if (chomp(my $tmp = $n)) {
    $self->emit(readln => $n);
    $n = '';
  }
  $self->{chunk} = $n;
}

1;
