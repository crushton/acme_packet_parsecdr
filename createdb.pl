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

my @completed_versions = (
    { name => "C610", type => "start" },
    { name => "C620", type => "start" },
    { name => "C620", type => "stop" },
    { name => "C630", type => "start" },
    { name => "C630", type => "stop" },
    { name => "C640", type => "start" },
    { name => "C640", type => "stop" },
);

my $dbname = "db/cdrdata.db";

my $dbh =
  DBI->connect( "dbi:SQLite:dbname=$dbname", "", "", { RaiseError => 1 }, )
  or die $DBI::errstr;

$dbh->do("DROP TABLE IF EXISTS Versions");
$dbh->do(
"CREATE TABLE Versions(Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT, Type TXT)"
);
while ( ( my $x, my $y ) = each(@completed_versions) ) {
    my $version = $y->{name};
    my $type    = $y->{type};
    my $sth = $dbh->prepare("INSERT INTO Versions (Name, Type) VALUES(?, ?)");
    $sth->execute( $version, $type );
}
$dbh->do("DROP TABLE IF EXISTS Records");
$dbh->do(
"CREATE TABLE Records(Id INTEGER PRIMARY KEY AUTOINCREMENT, Versions_Id INT, Placement INT, Name TEXT, VSA_Id)"
);

while ( ( my $x, my $y ) = each(@completed_versions) ) {
    my $version = $y->{name};
    my $type    = $y->{type};
    my $sth;
    my $id;

    $sth = $dbh->prepare(
        "SELECT Id FROM Versions WHERE Name='$version' AND Type='$type'");
    $sth->execute();
    $id = $sth->fetchrow();

    my $filename = "./db/" . $version . "_" . $type . ".csv";
    open( FH, $filename );
    while (<FH>) {
        chomp;
        my @values = split( /,/, $_ );
        if ( $values[2] eq "nil" ) {
            $values[2] = 0;
        }
        my $sql =
"INSERT INTO Records (Versions_Id, Placement, Name, VSA_Id) VALUES(?, ?, ?, ?)";
        $sth = $dbh->prepare($sql);
        $sth->execute( $id, $values[0], $values[1], $values[2] );
    }
    close(FH);
}

$dbh->disconnect();

say "Done creating database...";
