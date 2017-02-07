
package Mojo::IOLoop::LineReader;

# ABSTRACT: Non-blocking line-oriented input stream

use Mojo::Base 'Mojo::EventEmitter';

use Mojo::IOLoop::Stream;
use Scalar::Util ();

has 'stream';
has 'input_record_separator';

sub close            { shift->stream->close(@_) }
sub close_gracefully { shift->stream->close_gracefully(@_) }
sub handle           { shift->stream->handle(@_) }

sub new {
    my $self = shift->SUPER::new( chunk => '', input_record_separator => $/ );
    my $stream = $self->_build_stream(shift);
    return $self->stream($stream);
}

sub _build_stream {
    my $self   = shift;
    my $stream = Mojo::IOLoop::Stream->new(shift);

    Scalar::Util::weaken($self);
    $stream->on( close => sub { shift; $self->_close(@_) } );
    $stream->on( error   => sub { shift; $self->emit( error   => @_ ) } );
    $stream->on( read    => sub { shift; $self->_read(@_) } );
    $stream->on( timeout => sub { shift; $self->emit( timeout => @_ ) } );

    return $stream;
}

sub reactor      { shift->stream->reactor(@_) }
sub timeout      { shift->stream->timeout(@_) }
sub is_readable  { shift->stream->is_readable(@_) }
sub steal_handle { shift->stream->steal_handle(@_) }
sub start        { shift->stream->start(@_) }
sub stop         { shift->stream->stop(@_) }

sub _close {
    my ($self) = @_;
    $self->emit( read => $self->{chunk} ) if length $self->{chunk};
    $self->{chunk} = '';
    $self->emit( close => );
}

sub _read {
    my ( $self, $bytes ) = @_;

    open my $r, '<', \$bytes;
    my $n;
    local $/ = $self->input_record_separator;
    while (<$r>) {
        unless ( defined $n ) {
            $n = $self->{chunk} . $_;
            next;
        }
        $self->emit( read => $n );
        $n = $_;
    }
    if ( chomp( my $tmp = $n ) ) {
        $self->emit( read => $n );
        $n = '';
    }
    $self->{chunk} = $n;
}

1;
