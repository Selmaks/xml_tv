#!/usr/bin/env perl
#
#

use strict;
use warnings;
#use diagnostics;

use lib qw(.);

use XML::TV;
use XML::TV::ToolBox;

my %map = (
	'&' => 'and',
);
my $chars = join '', keys %map;

my %DUPLICATE_CHANNELS = ();
my @DUPLICATED_CHANNELS = ();
my @dupes;
my @CHANNELDATA;
my @DUPECHANDATA;
my @DUPEGUIDEDATA;
my $FVICONS;
my $DVBTRIPLET;
my $FVICONURL;
my @GUIDEDATA;
my $REGION_TIMEZONE;
my $REGION_NAME;
my $CACHEFILE = "yourtv.db";
my $CACHETIME = 86400; # 1 day - don't change this unless you know what you are doing.
my $TMPCACHEFILE = ".$$.yourtv-tmp-cache.db";

my (%dbm_hash, %thrdret);
local (*DBMRO, *DBMRW);

my ($country, $format) = ("Australia", "PlexXML");
my ($debug, $verbose, $pretty, $usefreeviewicons, $numdays, $ignorechannels, $includechannels, $region, $outputfile, $help) = (0, 0, 0, 0, 7, undef, undef, undef, undef, undef);
GetOptions
(
        'debug'         => \$debug,
        'verbose'       => \$verbose,
        'pretty'        => \$pretty,
        'days=i'        => \$numdays,
        'region=s'      => \$region,
        'output=s'      => \$outputfile,
        'ignore=s'      => \$ignorechannels,
        'include=s'     => \$includechannels,
        'fvicons'       => \$usefreeviewicons,
        'cachefile=s'   => \$CACHEFILE,
        'cachetime=i'   => \$CACHETIME,
        'duplicates=s'  => \@dupes,
	'format=s'	=> \$format,
	'country=s'	=> \$country,
        'help|?'        => \$help,
) or die ("Syntax Error!  Try $0 --help");

my $tv = XML::TV->new(
			Debug	=> $debug,
			Verbose	=> $verbose,
			Country	=> $country,
			Region	=> $region,
			Output	=> $outputfile,
			Format	=> $format,
		     );
my $tools = XML::TV::ToolBox->new(
					Debug	=> $debug,
					Verbose	=> $verbose,
				 );

@DUPELICATE_CHANNELS = $tools->get_duplicate_channels(@dupes) if (@dupes and scalar @dupes);
