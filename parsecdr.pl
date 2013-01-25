#!/usr/bin/env perl
###
## Copyright (c) 2013, Chris Rushton
##
## Permission to use, copy, modify, and distribute this software for any
## purpose with or without fee is hereby granted, provided that the above
## copyright notice and this permission notice appear in all copies.
##
## THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
## WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
## MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
## ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
## WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
## ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
## OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
###
use strict;
use diagnostics;
use warnings 'all';
use autodie;
use v5.10;
use DBI;
use Getopt::Long;
use Pod::Usage;
use constant false => 0;
use constant true  => 1;

my $dbname       = "db/cdrdata.db";
my $verbose      = '';
my $showrecord   = '';
my $help         = '';
my $version_vsa  = 56;
GetOptions(
    'verbose'    => \$verbose,
    'showrecord' => \$showrecord,
    'help'       => \$help
);

if ($help) {
    pod2usage(1);
}
elsif (@ARGV < 1) {
    pod2usage(2);
}
my $filename     = $ARGV[0];
my $out_filename = $filename . "_out.csv";

# Load CDR file given on CLI into script array @records
xlog( "Loading file " . $filename . " ..." );
open my $FH, '<', $filename;
my @records;
while (<$FH>) {
    chomp;
    push( @records, $_ );
}
close $FH;
xlog( "Found Records: " . @records );

# end

# Connect to CDR index database with handle $dbh
xlog("Connecting to CDR database ...");
my $dbh =
  DBI->connect( "dbi:SQLite:dbname=$dbname", "", "", { RaiseError => 1 }, )
  or die $DBI::errstr;

# end

# create an array of uniq cdr sbc versions available based upon the database types
my $sth = $dbh->prepare("SELECT Name FROM Versions LIMIT 100");
$sth->execute;

my %sbc_versions;
while ( my $row = $sth->fetchrow_array() ) {
    $sbc_versions{$row} = 1;
}

# end

xlog("Starting CDR Analysis and Parsing ...");
xlog("----");

# Main loop to analyze each CDR and stuff it into a new array called @newrecords
my $count = 1;
my @newrecords;
foreach (@records) {
    my $sql;
    my $sth;
    my $record_type;    # array with string of each complete record
    my @cdr_record
      ;    # array of individual items in each cdr record split by commas
    xlog( "Record Number: " . $count );
    $count++;

    # remove all quotes from string
    $_ =~ s/"//g;

    # determine record type start, stop, other
    @cdr_record = split( /,/, $_ );
    xlog( "Record Fields: " . @cdr_record );
    if ( $cdr_record[0] eq "1" ) {
        $record_type = "start";
    }
    elsif ( $cdr_record[0] eq "2" ) {
        $record_type = "stop";
    }
    else {
        $record_type = "interim";
        xlog(
            "Unsupported record type: " . $cdr_record[0] . ", continuing ..." );
        xlog("----");
        next;
    }
    xlog( "Found Record Type: " . $record_type );

  # determine sbc version from record using known locations in db with VSA Id 56
    my $record_version;
    $sql = join( " ",
        "SELECT R.Placement FROM Versions",
        "AS V JOIN Records AS R ON V.Id=R.Versions_Id",
        "WHERE R.VSA_Id=? AND V.Type=?;" );
    $sth = $dbh->prepare($sql);
    $sth->execute( $version_vsa, $record_type );

    my @sbc_version_locations;
    while ( my $row = $sth->fetchrow_array() ) {
        push( @sbc_version_locations, $row );
    }
    @sbc_version_locations = uniq(@sbc_version_locations);

    foreach (@sbc_version_locations) {
        my $key = $_ - 1;
        if (   exists( $cdr_record[$key] )
            && $cdr_record[$key] =~ m/Build/i
            && $cdr_record[$key] =~ m/(([A-Z]{1,3})(\d)\.(\d)\.(\d))/i )
        {
            xlog( "Found Record Version: " . $cdr_record[$key] );
            my $version = $3 . $4 . $5;
            if ( $2 =~ m/^SCX$/i || $2 =~ m/^SC^/i ) {
                $record_version = "C" . $version;
            }
            elsif ( $2 =~ m/^D$/i ) {
                $record_version = "D" . $version;
            }
        }
    }
    if ( !$record_version ) {
        xlog(
"Unable to determine CDR version type from known string locations, continuing ..."
        );
        xlog("----");
        next;
    }
    if ( !exists( $sbc_versions{$record_version} ) ) {
        xlog("Unsupported SBC Software Type/Version Combo, continuing ...");
        xlog("----");
        next;
    }

# Use determined record type and version in order to update all records to 
# include the VSA name in them using the KVP format key=value, also strip all
# quotes out and replace values with quotes regardless of whether the sbc sends 
# them or not

    $sql = join( " ",
        "SELECT R.Name FROM Versions",
        "AS V JOIN Records AS R ON V.Id=R.Versions_Id",
        "WHERE V.Name=? AND V.Type=?;" );
    $sth = $dbh->prepare($sql);
    $sth->execute( $record_version, $record_type );

    my @returned_vsa_names;
    while ( my $row = $sth->fetchrow_array() ) {
        push( @returned_vsa_names, $row );
    }

    my @newcdr_vsa;
    for ( my $i = 0 ; $i < @returned_vsa_names ; $i++ ) {
        my $string = $returned_vsa_names[$i] . '="' . $cdr_record[$i] . '"';
        push( @newcdr_vsa, $string );
    }
    push( @newrecords, join( ",", @newcdr_vsa ) );
    say join( ",", @newcdr_vsa ) if $showrecord;

    # end

    xlog("----");
}

# end
$dbh->disconnect();

# creating new csv file with updated records
if ( @newrecords > 0 ) {
    open my $FH, '>', $out_filename;
    foreach (@newrecords) {
        say $FH $_;
    }
    close $FH;
    say "Created file: " . $out_filename;
    if ( @records - @newrecords > 0 ) {
        say(    "There were "
              . ( @records - @newrecords )
              . " records with errors." );
    }
}

# function to log to screen if verbose is set
sub xlog {
    say $_[0] if $verbose;
}

# function to gracefully exit while displaying a message
sub gexit {
    say $_[0];
    exit 1;
}

# function to return a sorted uniq array givin any array
sub uniq {
    my %seen;
    return sort( grep( !$seen{$_}++, @_ ) );
}

sub usage {

}

__END__

=head1 NAME

parsecdr.pl - Perl scrpt to parse Acme Packet CDR Files

=head1 SYNOPSIS

parsecdr.pl [options] <cdr file>

=head1 OPTIONS

=over 8

=item B<-h, -help>

Print a brief help message and exits.

=item B<-v, -verbose>

Prints record information to screen

=item B<-s, -showmessage>

Prints parsed record to screen

=back

=head1 DESCRIPTION

Bparsecdr.pl will read the given input file and add in 
the Acme Packet specific VSA names to the files in KVP format

=cut
