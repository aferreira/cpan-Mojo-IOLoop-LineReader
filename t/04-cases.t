
use Mojo::Base -strict;

use Test::More;

use MojoX::LineReader;
use File::Temp qw(tempfile SEEK_SET);

# This tests lines as read by LineReader match simple <> loop

my @TESTS = (
    {   content => [],
        name    => 'empty file',
    },
    {   content => [
            'a' x 30 . "\n",    #
            'b' x 20 . "\n",    #
            'c' x 25 . "\n",    #
            'd' x 10
        ],
        name => 'regular file'
    },
    {   content => [],
        name    => 'file with "0"',
    },
    {   content => [ "a\n\n", "b\nc\n\n", "d\n\n\n", ],
        name    => 'file by paragraphs',

        input_record_separator => '',
    },
    {   content => [
            "---\na:3\n...\n",        #
            "---\n[1,2,3]\n...\n",    #
            "---\nx: 42\ny: 43\n...\n",
        ],
        name => 'file with "\n...\n" separator',

        input_record_separator => "\n...\n",
    },
    {   content => [ "The quick brown fox jumps over the lazy dog\n" x 10 ],
        name    => 'file with undef separator',

        input_record_separator => undef,
    }
);

plan tests => scalar @TESTS;

for my $t (@TESTS) {
    my @content = @{ $t->{content} };
    my $name    = $t->{name};                            # FIXME use test name
    my $rs      = $t->{input_record_separator} // "\n";

    # Write content to temp file
    my $tmp = tempfile();
    print {$tmp} join( '', @content );
    $tmp->seek( 0, SEEK_SET );                           # rewind

    # use <>
    my @expected = do { local $/ = $rs; <$tmp> };
    push @expected, \"eof";
    $tmp->seek( 0, SEEK_SET );                           # rewind

    # use LineReader
    my @output;
    local $/ = $rs;
    my $r = MojoX::LineReader->new($tmp);
    $r->on( read => sub { my ( $r, $line ) = @_; push @output, $line; } );
    $r->on( close => sub { push @output, \"eof"; } );
    $r->start;
    $r->reactor->start;

    is_deeply( \@output, \@expected, $name );
}

