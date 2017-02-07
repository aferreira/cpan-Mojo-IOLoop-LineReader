
package MojoX::LineReader;

# ABSTRACT: Non-blocking line-oriented input stream

use Mojo::Base 'Mojo::EventEmitter';

use Mojo::IOLoop::Stream;

has 'stream';

sub new {
    my ( $self, $handle ) = @_;
    my $reader = $self->SUPER::new( chunk => '' );

    my $stream = Mojo::IOLoop::Stream->new($handle);

    $stream->on( read  => sub { shift; $reader->_read(@_) } );
    $stream->on( close => sub { shift; $reader->_close(@_) } );

    $stream->on( error   => sub { shift; $reader->emit( error   => @_ ) } );
    $stream->on( timeout => sub { shift; $reader->emit( timeout => @_ ) } );

    return $reader->stream($stream);
}

sub _read {
    my ( $self, $bytes ) = @_;

    # Break bytes into lines
    open my $r, '<', \$bytes;
    my $n;
    while (<$r>) {
        unless ( defined $n ) {

            # Glue previous chunk to first line
            $n = $self->{chunk} . $_;
            next;
        }

        # Emit 'read' event
        $self->emit( read => $n );
        $n = $_;
    }
    if ( chomp( my $tmp = $n ) ) {    # Line?
        $self->emit( read => $n );
        $n = '';
    }
    $self->{chunk} = $n;
}

sub _close {
    my ($self) = @_;

    # Emit last 'read' event
    $self->emit( read => $self->{chunk} ) if length $self->{chunk};
    $self->{chunk} = '';

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
