package Test::Format;

=encoding UTF-8

=cut

use strict;
use warnings FATAL => 'all';
use utf8;
use open qw(:std :utf8);

use Test::More;
use JSON::PP;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    test_format
);
our @EXPORT = @EXPORT_OK;

=head2 test_format

=cut

sub test_format {
    my (@opts) = @_;

    die 'Must specifgy opts' if scalar(@opts) == 0;
    die 'There must be key-value pairs' if scalar(@opts) % 2;

    my %opts = @opts;

    my $files = delete $opts{files};
    my $format = delete $opts{format};
    my $format_sub = delete $opts{format_sub};

    my @unknown_opts = keys %opts;
    die 'Unknown opts: ' . join(', ', @unknown_opts) if @unknown_opts;

    die "Must specify 'files'" if not defined $files;
    die "'files' must be an array" if ref $files ne 'ARRAY';
    die "'files' can't be an empty array" if scalar(@{$files}) == 0;

    die "Must specify 'format' or 'format_sub'" if !defined($format) && !defined($format_sub);
    die "Can't specify both 'format' and 'format_sub'" if defined($format) && defined($format_sub);

    die "Unknown value for 'format' opt: '$format'" if defined($format) && $format ne 'pretty_json';
    die "'format_sub' must be sub" if defined($format_sub) && ref($format_sub) ne 'CODE';

    my $sub = defined($format) && $format eq 'pretty_json' ? \&_pretty_json : $format_sub;

    foreach my $file (@{$files}) {
        foreach my $file_name (glob $file) {
            if (-e $file_name) {

                # $content is chars, not bytes
                my $content = _read_file($file_name);

                my $expected_content = $sub->($content);

                if ($ENV{SELF_UPDATE}) {
                    if ($content eq $expected_content) {
                        pass("File $file_name is in expected format"),
                    } else {
                        _write_file($file_name, $expected_content);
                        pass("Writing fixed file $file_name");
                    }
                } else {
                    is($content, $expected_content, "File $file_name is in expected format"),
                }
            } else {
                fail("File $file_name does not exist");
            }
        }
    }

    return 1;
}

sub _pretty_json {
    my ($content) = @_;

    my $json_coder = JSON::PP
        ->new
        ->pretty
        ->canonical
        ->indent_length(4)
        ;

    my $data = JSON::PP->new->decode($content);
    my $pretty_json = $json_coder->encode($data);

    return $pretty_json;
}

sub _read_file {
    my ($file_name) = @_;

    my $content = '';

    open FH, '<', $file_name or die "Can't open < $file_name for reading: $!";

    while (<FH>) {
        $content .= $_;
    }

    return $content;
}

sub _write_file {
    my ($file_name, $content) = @_;

    open FH, '>', $file_name or die "Can't open $file_name for writing: $!";

    print FH $content;

    return 1;
}

1;
