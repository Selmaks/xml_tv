#!/usr/bin/perl
use strict;
use warnings;
use DateTime;
use Getopt::Long;
use LWP::UserAgent;
use XML::Simple;

my %SBSRADIO;
$SBSRADIO{"36"}{name}	= "SBS Arabic24";
$SBSRADIO{"36"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbsarabic24_300_colour.png";
$SBSRADIO{"36"}{servicename}	= "poparaby";
$SBSRADIO{"37"}{name}	= "SBS Radio 1";
$SBSRADIO{"37"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbs1_300_colour.png";
$SBSRADIO{"37"}{servicename}	= "sbs1";
$SBSRADIO{"38"}{name}	= "SBS Radio 2";
$SBSRADIO{"38"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbs2_300_colour.png";
$SBSRADIO{"38"}{servicename}	= "sbs2";
$SBSRADIO{"39"}{name}	= "SBS Chill";
$SBSRADIO{"39"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/header_chill_300_colour.png";
$SBSRADIO{"39"}{servicename}	= "chill";

$SBSRADIO{"301"}{name}	= "SBS Radio 1";
$SBSRADIO{"301"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbs1_300_colour.png";
$SBSRADIO{"301"}{servicename}	= "sbs1";

$SBSRADIO{"302"}{name}	= "SBS Radio 2";
$SBSRADIO{"302"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbs2_300_colour.png";
$SBSRADIO{"302"}{servicename}	= "sbs2";

$SBSRADIO{"303"}{name}	= "SBS Radio 3";
$SBSRADIO{"303"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbs3_300_colour.png";
$SBSRADIO{"303"}{servicename}	= "sbs3";

$SBSRADIO{"304"}{name}	= "SBS Arabic24";
$SBSRADIO{"304"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbsarabic24_300_colour.png";
$SBSRADIO{"304"}{servicename}	= "poparaby";

$SBSRADIO{"305"}{name}	= "SBS PopDesi";
$SBSRADIO{"305"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/header_popdesi_300_colour.png";
$SBSRADIO{"305"}{servicename}	= "popdesi";

$SBSRADIO{"306"}{name}	= "SBS Chill";
$SBSRADIO{"306"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/header_chill_300_colour.png";
$SBSRADIO{"306"}{servicename}	= "chill";

$SBSRADIO{"307"}{name}	= "SBS PopAsia";
$SBSRADIO{"307"}{iconurl}	= "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/header_popasia_300_colour.png";
$SBSRADIO{"307"}{servicename}	= "popasia";



sub sbs_getchannels
{
	my @tmpdata;
	my $count = 0;
	foreach my $key (keys %SBSRADIO)
	{
		$tmpdata[$count]->{name} = $SBSRADIO{$key}{name};
		$tmpdata[$count]->{id} = $key.".yourtv.com.au";
		$tmpdata[$count]->{lcn} = $key;
		$tmpdata[$count]->{icon} = $SBSRADIO{$key}{iconurl};
		$count++;
	}
	return @tmpdata;
}

sub sbs_getepg
{
	my ($ua, $NUMDAYS, $VERBOSE) = @_;
	my $showcount = 0;
	my @tmpguidedata;
	foreach my $key (keys %SBSRADIO)
	{
		my $id = $key;
		warn("Getting epg for $SBSRADIO{$key}{name} ...\n") if ($VERBOSE);
		my $now = time;;
		my ($ssec,$smin,$shour,$smday,$smon,$syear,$swday,$syday,$sisdst) = localtime(time);
		my ($esec,$emin,$ehour,$emday,$emon,$eyear,$ewday,$eyday,$eisdst) = localtime(time+(86400*$NUMDAYS));
		my $startdate = sprintf("%0.4d-%0.2d-%0.2dT%0.2d:%0.2d:%0.2dZ",($syear+1900),$smon+1,$smday,$shour,$smin,$ssec);
		my $enddate = sprintf("%0.4d-%0.2d-%0.2dT%0.2d:%0.2d:%0.2dZ",($eyear+1900),$emon+1,$emday,$ehour,$emin,$esec);

		my $url = "http://two.aim-data.com/services/schedule/sbs/".$SBSRADIO{$key}{servicename}."?days=".$NUMDAYS;
		my $res = $ua->get($url);
		warn("Getting channel program listing for $key ( $url )...\n") if ($VERBOSE);
		die("Unable to connect to ABC. [" . $res->status_line . "]\n") if (!$res->is_success);
		my $data = $res->content;
		my $tmpdata;
		eval {
			$tmpdata = XMLin($data);
			1;
		};
		$tmpdata = $tmpdata->{entry};
		if (defined($tmpdata))
		{
			my $count = 0;
			foreach my $key (keys %$tmpdata)
			{
				$tmpguidedata[$showcount]->{id} = $id.".yourtv.com.au";
				$tmpguidedata[$showcount]->{start} = $tmpdata->{$key}->{start};
				$tmpguidedata[$showcount]->{start} =~ s/[-T:\s]//g;
				$tmpguidedata[$showcount]->{start} =~ s/(\+)/00 +/;
				$tmpguidedata[$showcount]->{stop} = $tmpdata->{$key}->{end};
				$tmpguidedata[$showcount]->{stop} =~ s/[-T:\s]//g;
				$tmpguidedata[$showcount]->{stop} =~ s/(\+)/00 +/;
				$tmpguidedata[$showcount]->{channel} = $SBSRADIO{$key}{name};
				$tmpguidedata[$showcount]->{title} = $tmpdata->{$key}->{title};
				my $catcount = 0;
				push(@{$tmpguidedata[$showcount]->{category}}, "Radio");
				my $desc = $tmpdata->{$key}->{description};
				$tmpguidedata[$showcount]->{desc} = $tmpdata->{$key}->{description} if (!(ref $desc eq ref {}));
				$showcount++;

			}
		}

	}
	warn("Processed a totol of $showcount shows ...\n") if ($VERBOSE);
	return \@tmpguidedata;
}
