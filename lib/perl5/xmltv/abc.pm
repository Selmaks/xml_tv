#!/usr/bin/perl

use strict;
use warnings;

my %ABCRADIO;
$ABCRADIO{"200"}{name}	= "Double J";
$ABCRADIO{"200"}{iconurl}	= "https://www.abc.net.au/cm/lb/8811932/thumbnail/station-logo-thumbnail.jpg";
$ABCRADIO{"200"}{servicename}	= "doublej";
$ABCRADIO{"201"}{name}	= "ABC Jazz";
$ABCRADIO{"201"}{iconurl}	= "https://www.abc.net.au/cm/lb/8785730/thumbnail/station-logo-thumbnail.png";
$ABCRADIO{"201"}{servicename}	= "jazz";

sub abc_getchannels
{
	my $verbose = shift;
	my $count = 0;
	my @tmpdata;
	foreach my $key (keys %ABCRADIO)
	{
		warn("Getting channels for $ABCRADIO{$key}{name} ...\n") if ($verbose);
		$tmpdata[$count]->{name} = $ABCRADIO{$key}{name};
		$tmpdata[$count]->{id} = $key.".yourtv.com.au";
		$tmpdata[$count]->{lcn} = $key;
		$tmpdata[$count]->{icon} = $ABCRADIO{$key}{iconurl};
		$count++;
	}
	return @tmpdata;
}

sub abc_getepg
{
	my ($ua, $NUMDAYS, $VERBOSE) = @_;
	my $showcount = 0;
	my @tmpguidedata;
	foreach my $key (keys %ABCRADIO)
	{
		my $id = $key;
		warn("Getting epg for $ABCRADIO{$key}{name} ...\n") if ($VERBOSE);
		my ($ssec,$smin,$shour,$smday,$smon,$syear,$swday,$syday,$sisdst) = localtime(time);
		my ($esec,$emin,$ehour,$emday,$emon,$eyear,$ewday,$eyday,$eisdst) = localtime(time+(86400*$NUMDAYS));
		my $startdate = sprintf("%0.4d-%0.2d-%0.2dT%0.2d:%0.2d:%0.2dZ",($syear+1900),$smon+1,$smday,$shour,$smin,$ssec);
		my $enddate = sprintf("%0.4d-%0.2d-%0.2dT%0.2d:%0.2d:%0.2dZ",($eyear+1900),$emon+1,$emday,$ehour,$emin,$esec);

		my $url = URI->new( 'https://program.abcradio.net.au/api/v1/programitems/search.json' );
		$url->query_form(service => $ABCRADIO{$key}{servicename}, limit => '100', order => 'asc', order_by => 'ppe_date', from => $startdate, to => $enddate);
		my $res = $ua->get($url);
		warn("Getting channel program listing for $key ( $url )...\n") if ($VERBOSE);
		die("Unable to connect to ABC. [" . $res->status_line . "]\n") if (!$res->is_success);
		my $tmpdata;
		eval {
			 $tmpdata = JSON->new->relaxed(1)->allow_nonref(1)->decode($res->content);
			1;
		};
		$tmpdata = $tmpdata->{items};
		if (defined($tmpdata))
		{
			for (my $count = 0; $count < @$tmpdata; $count++)
			{
				$tmpguidedata[$showcount]->{id} = $key.".yourtv.com.au";
				$tmpguidedata[$showcount]->{start} = $tmpdata->[$count]->{live}[0]->{start};
				$tmpguidedata[$showcount]->{start} = toLocalTimeString($tmpdata->[$count]->{live}[0]->{start},'UTC');
				my $duration = $tmpdata->[$count]->{live}[0]->{duration_seconds}/60;
				$tmpguidedata[$showcount]->{stop} = addTime($duration,$tmpguidedata[$showcount]->{start});
				$tmpguidedata[$showcount]->{start} =~ s/[-T:]//g;
				$tmpguidedata[$showcount]->{start} =~ s/\+/ \+/g;
				$tmpguidedata[$showcount]->{stop} =~ s/[-T:]//g;
				$tmpguidedata[$showcount]->{stop} =~ s/\+/ \+/g;

				$tmpguidedata[$showcount]->{channel} = $ABCRADIO{$key}{name};
				$tmpguidedata[$showcount]->{title} = $tmpdata->[$count]->{title};
				my $catcount = 0;
				push(@{$tmpguidedata[$showcount]->{category}}, "Radio");
				foreach my $tmpcat (@{$tmpdata->[$count]->{categories}})
				{
					push(@{$tmpguidedata[$showcount]->{category}}, $tmpcat->{label});
						$catcount++;
				}
				$tmpguidedata[$showcount]->{desc} = $tmpdata->[$count]->{short_sypnosis};
				$showcount++;

			}
		}

	}
	warn("Processed a totol of $showcount shows ...\n") if ($VERBOSE);
	return @tmpguidedata;
}

