#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;
use local::lib '~/git/xmltv';
use xmltv;

#my $sbs = xmltv->new(source => 'sbs', region => 'Sydney', epgdays => 7, includechannels => '6', ignorechannels => '6', duplicatechannels => 'n', verbose => '1') ;
my $abc = xmltv->new(source => 'abc', epgdays => 7) ;
my $sbs = xmltv->new(source => 'sbs', epgdays => 7) ;
#print Dumper $abc;

#print Dumper $max;
my @abcchannels = $abc->getchannels();
my @sbschannels = $sbs->getchannels();

my @abcepg = $abc->getepg( );
my @sbsepg = $sbs->getepg();

#my @channels = (@abcchannels,@sbschannels);
#my @epg = (@abcepg, @sbsepg);

$abc->buildxml();
$abc->writexml();

#print Dumper @channels;
#print Dumper @epg;

exit;

