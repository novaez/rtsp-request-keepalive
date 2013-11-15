#!/usr/bin/perl
#
# rtsp-request-keepalive: Command Line RTSP Tool 0.1
# Base on rtsp-request on http://www.kosho.org/tools/rtsp-request/
#

$|=0;
my $VERSION=0.1;

use File::Basename;
use Cwd 'abs_path';
use lib dirname(abs_path($0)) . '/perl-lib';

use Data::Dumper;
use Getopt::Std;
use RTSP::Lite::Keepalive;
use AnyEvent;


# Read schedule from files
my @requests;

while (<>) {
print "here\n";
    chomp;
    if (!/^#/) {
        my @r = split /,\s+/;
        push(@requests, \@r);
    }
}

if (!@requests) {
    print "Could not find request.\n";
    print "Usage: $0 [FILE]...\n";
    exit(1);
}


print Dumper @requests;
    

