#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;
use local::lib '~/git/xmltv';
use xmltv;

my $abc = xmltv->new(source => 'abc', epgdays => 7) ;
my $sbs = xmltv->new(source => 'sbs', epgdays => 7) ;
my @abcchannels = $abc->getchannels();
my @sbschannels = $sbs->getchannels();
my @abcepg = $abc->getepg();
my @sbsepg = $sbs->getepg();


my $guide = xmltv->new() ;
my %xml = ($abc, $sbs);
$guide = xmltv->buildxml(xmltv => [$abc, $sbs], verbose => 1, pretty => 1);

$guide->writexml(output => '/tmp/out.xml');

#print Dumper @channels;
#print Dumper @epg;

exit;

