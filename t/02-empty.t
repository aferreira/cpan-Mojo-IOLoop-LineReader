
use Mojo::Base -strict;

use Test::More;

use MojoX::LineReader;
use File::Temp qw(tempfile SEEK_SET);

# Create an empty temp file
my $tmp = tempfile();
print {$tmp} '';
$tmp->seek( 0, SEEK_SET );    # rewind

my $r = MojoX::LineReader->new($tmp);
$r->on(
    read => sub {
        my ( $r, $line ) = @_;
        fail("No 'read' event expected");
    }
);
$r->on(
    close => sub {
        pass("eof");
    }
);

$r->start;
$r->reactor->start;
done_testing;

