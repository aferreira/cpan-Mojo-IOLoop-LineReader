
use 5.016;

package MojoX::LineReader;

# ABSTRACT: Non-blocking line-oriented input stream

use Mojo::Base 'Mojo::EventEmitter';

use Mojo::IOLoop::Stream;

has 'stream';

has '_prefix' => '';

sub new {
    my ( $self, $handle ) = @_;
    my $reader = $self->SUPER::new();

    my $stream = Mojo::IOLoop::Stream->new($handle);

    $stream->on( read  => sub { shift; $reader->on_read(@_) } );
    $stream->on( close => sub { shift; $reader->on_close(@_) } );

    $stream->on( error   => sub { shift; $reader->emit( error   => @_ ) } );
    $stream->on( timeout => sub { shift; $reader->emit( timeout => @_ ) } );

    return $reader->stream($stream);
}

sub on_read {
    my ( $self, $bytes ) = @_;

    # Break bytes into lines
    open my $r, '<', \$bytes;
    my @lines = <$r>;

    # Glue last prefix to first line
    $_ = $self->_prefix . $_ for $lines[0];

    # Compute next prefix
    $self->_prefix( chomp() ? '' : pop @lines ) for ( my $copy = $lines[-1] );

    # Emit 'read' events
    $self->emit( read => $_ ) for @lines;
}

sub on_close {
    my ($self) = @_;

    if ( my $line = $self->_prefix ) {

        # Emit last 'read' event
        $self->emit( read => $line );
        $self->_prefix('');
    }

    # Emit 'close' event
    $self->emit( close => );
}

sub close { shift->stream->close(@_) }

sub close_gracefully { shift->stream->close_gracefully(@_) }

sub handle  { shift->stream->handle(@_) }
sub reactor { shift->stream->reactor(@_) }
sub timeout { shift->stream->timeout(@_) }

sub is_readable  { shift->stream->is_readable(@_) }
sub steal_handle { shift->stream->steal_handle(@_) }

sub start { shift->stream->start(@_) }
sub stop  { shift->stream->stop(@_) }

1;
