#!/usr/bin/env perl
use strict;
use diagnostics;
use warnings 'all';
use autodie;
use v5.10;

use DBI;

my $filename = $ARGV[0];
my $out_filename = $filename."_out.csv";
my $dbname="db/cdrdata.db";
my $debug = 1;

# Load CDR file given on CLI into script array @records
if ($debug) { say "Loading file ".$filename." ..."; }
open my $FH, '<', $filename;
my @records;
while (my $line = <$FH>)
{
  chomp($line);
  push(@records, $line);
}
close $FH;

# Connect to CDR index database with handle $dbh
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
  { RaiseError => 1 },) or die $DBI::errstr;

$dbh->disconnect();

