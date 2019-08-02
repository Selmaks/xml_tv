# XML::TV::Output::PlexXML

package XML::TV::Output::PlexXML;

use strict;
use warnings;
use diagnostics;

use vars qw($VERSION);

use XML::Writer;
use Data::Dumper;

# If we use this the debug/verbose accessors will be inherited
use parent -norequire, 'Output';

my $VERSION = sprintf("%d.%d.%d.%d.%d.%d", q$Id: PlexXML.pm 700 2019-05-29 15:32:08Z  $ =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)Z/);

sub new
{
	my $class = shift;
	my $self = {};
	bless $self;

	my %arg = @_;

#	$self->debug(exists $arg{Debug} ? $arg{Debug} : undef);
#	$self->pretty(exists $arg{Pretty} ? $arg{Pretty} : undef);
#	$self->verbose(exists $arg{Verbose} ? $arg{Verbose} : undef);

	$self->data(exists $arg{Data} ? $arg{Data} : undef); # file or stdout
	$self->srcinfo(exists $arg{SourceInfo} ? $arg{SourceInfo} : undef);
	$self->srcurl(exists $arg{SourceURL} ? $arg{SourceURL} : undef);
	
	return $self;
}

#sub debug
#{
#	my $self = shift;
#	if (@_) {$self->{DEBUG} = $_[0]};
#	$self->{DEBUG} = undef if (!defined $self->{DEBUG});
#	return $self->{DEBUG};
#}
#
#sub pretty
#{
#	my $self = shift;
#	if (@_) {$self->{PRETTY} = $_[0]};
#	$self->{PRETTY} = undef if (!defined $self->{PRETTY});
#	return $self->{PRETTY};
#}
#
#sub verbose
#{
#	my $self = shift;
#	if (@_) {$self->{VERBOSE} = $_[0]};
#	$self->{VERBOSE} = undef if (!defined $self->{VERBOSE});
#	return $self->{VERBOSE};
#}

# This is the incoming data
sub data
{
	my $self = shift;
	if (@_) {$self->{DATA} = $_[0]};
	$self->{DATA} = undef if (!defined $self->{DATA});
	return $self->{DATA};
}

sub srcinfo
{
	my $self = shift;
	if (@_) {$self->{SRCINFO} = $_[0]};
	$self->{SRCINFO} = "Powered by XMLTV.net" if (!defined $self->{SRCINFO});
	return $self->{SRCINFO};
}

sub srcurl
{
	my $self = shift;
	if (@_) {$self->{SRCURL} = $_[0]};
	$self->{SRCURL} = "https://www.xmltv.net/" if (!defined $self->{SRCURL});
	return $self->{SRCURL};
}

# This is the handle for the output..  PlexXML just uses 
# XML::Writer so its quite simple, especially for the output
sub plexXML
{
	my $self = shift;
	if (@_) {$self->{PLEXXML} = $_[0]};
	$self->{PLEXXML} = XML::Writer->new(OUTPUT => 'self', DATA_MODE => ($self->pretty ? 1 : 0), DATA_INDENT => ($self->pretty ? 8 : 0) ) if (!defined $self->{PLEXXML});
	return $self->{PLEXXML};
}

# 'out' is the same in each output module - this is where the text will be
# in the case of XML::Writer it jst $XML because printing it will
# just print the entire XML as built.  Others may have to have vars.
sub out
{
	my $self = shift;
	return $self->plexXML;
}

# Ok when the input data is loaded, this will ensure the output is written
# We have to be a little careful here as the input has to be a specific
# format and the output specific for this module.
#
# Input information is in $self->data
# output will be stored in $self->plexXML
sub process
{
	my $self = shift;
	$self->plexXML->xmlDecl("ISO-8859-1");
	$self->plexXML->doctype("tv", undef, "xmltv.dtd");
	$self->plexXML->emptyTag("tv", date => time(), 'source-info-url' => $self->srcurl, 'source-info-name' => $self->srcinfo);
	$self->plexXML->startTag('tv', 'generator-info-url' => "http://www.xmltv.org/");
	$self->build_channels();
	$self->build_guide();
	$self->plexXML->endTag('tv');
}

sub build_channels
{
	$self = shift;
	my $guidedata = $self->data->guide;
	my $channeldata = $self->data->channel;

	foreach my $items (@$guidedata)
	{
		my $channelnumber;
		my $channelname;
		my $channel = $items->{GuideNumber};
		foreach my $lineup (@$channeldata)
		{
			if ($lineup->{GuideNumber} eq $items->{GuideNumber})
			{
				$channelname = $lineup->{GuideName};
			}
		}
		$self->plexXML->startTag('channel', 'id' => $channel . ".hdhomerun.com");
		$self->plexXML->dataElement('display-name', $channelname);
		$self->plexXML->dataElement('lcn', $channel);
		$self->plexXML->emptyTag('icon', 'src' => $items->{ImageURL}) if (defined($items->{ImageURL}));
		$self->plexXML->endTag('channel');
	}
}

sub build_guide
{
	my $self = shift;

	foreach my $items (@$channeldata)
	{
		my $channel = $items->{GuideNumber};
		my $channelid = $items->{GuideName};
		my $starttime = time();
		warn("Getting program guide for channel $channelid...\n") if ($VERBOSE);
		while (1)
		{
			## THis has to go (it needs to be over in Feeds)
			#$req = HTTP::Request->new(GET => 'http://ipv4-api.hdhomerun.com/api/guide.php?DeviceAuth=' . $DeviceAuth . '&Channel=' . $channel . '&Start=' . $starttime);
			#$res = $ua->request($req);
			#if (!$res->is_success)
			#{
			#	warn("Error: Unable to get program guide for channel $channelid skipping...\n");
			#	last;
			#}
			#if ($res->content eq "null")
			#{
			#	warn("Finished channel $channelid...\n\n") if ($VERBOSE);
			#	last;
			#}
			#$guide->{$channel} = decode_json($res->content);
			warn("Processing program guide for channel $channelid...\n") if ($VERBOSE);
			# send over the reference to the XML object rather than using it in global scope.
			$self->build_programs($channel . ".hdhomerun.com", $guide->{$channel}[0]->{Guide});
			my $size = scalar @{ $guide->{$channel}[0]->{Guide}} - 1;
			$starttime = $guide->{$channel}[0]->{Guide}[$size]->{EndTime};
		}
	}
}

sub build_programs
{
	my $self = shift;
	my ($channelid, $data) = @_;
	foreach my $items (@$data)
	{
		my $starttime = $items->{StartTime};
		my $endtime = $items->{EndTime};
		my $title = $items->{Title};
		my $movie = 0;
		my $originalairdate = "";
		my ($ssec,$smin,$shour,$smday,$smon,$syear,$swday,$syday,$sisdst) = localtime($starttime);
		my ($esec,$emin,$ehour,$emday,$emon,$eyear,$ewday,$eyday,$eisdst) = localtime($endtime);
		# should do this with strftime, but hey-ho, this'll do
		my $startdate = sprintf("%0.4d%0.2d%0.2d%0.2d%0.2d%0.2d",($syear+1900),$smon+1,$smday,$shour,$smin,$ssec);
		my $senddate = sprintf("%0.4d%0.2d%0.2d%0.2d%0.2d%0.2d",($eyear+1900),$emon+1,$emday,$ehour,$emin,$esec);
		$title =~ s/([$chars])/$map{$1}/g;
		$self->plexXML->startTag('programme', 'start' => "$startdate $TZ", 'stop' => "$senddate $TZ", 'channel' => $channelid);
		$self->plexXML->dataElement('title', $title);
		if (defined($items->{EpisodeTitle}))
		{
			my $subtitle = $items->{EpisodeTitle};
			$subtitle =~ s/([$chars])/$map{$1}/g;
			$self->plexXML->dataElement('sub-title', $subtitle);
		}
		if (defined($items->{Synopsis}))
		{
			my $description = $items->{Synopsis};
			$description =~ s/([$chars])/$map{$1}/g;
			$self->plexXML->dataElement('desc', $description);
		}
		if (defined($items->{Filter}))
		{
			foreach my $category (@{$items->{Filter}})
			{
				if ($category =~ /Movie/)
				{
					$movie = 1;
				}
				$self->plexXML->dataElement('category', $category);
			}
		}
		$self->plexXML->emptyTag('icon', 'src' => $items->{ImageURL}) if (defined($items->{ImageURL}));
		if (defined($items->{EpisodeNumber}))
		{
			my $series = 0;
			my $episode = 0;
			if ($items->{EpisodeNumber} =~ /^S(.+)E(.+)/)
			{
				($series, $episode) = ($1, $2);
				$self->plexXML->dataElement('episode-num', $items->{EpisodeNumber}, 'system' => 'SxxExx') if (defined($items->{EpisodeNumber}));
				$series--;
				$episode--;
			} elsif ($items->{EpisodeNumber} =~ /^EP(.*)-(.*)/) {
				($series, $episode) = ($1, $2);
				$series--;
				$episode--;
			} elsif ($items->{EpisodeNumber} =~ /^EP(.*)/) {
				$episode = $1;
				$episode--;
			}
			$series = 0 if ($series < 0);
			$episode = 0 if ($episode < 0);
			$self->plexXML->dataElement('episode-num', "$series.$episode.", 'system' => 'xmltv_ns') if (defined($items->{EpisodeNumber}));
		}
		if ((!defined($items->{EpisodeNumber})) and (!defined($items->{OriginalAirdate})) and !($movie))
		{
			my $startdate = sprintf("%0.4d-%0.2d-%0.2d %0.2d:%0.2d:%0.2d",($syear+1900),$smon+1,$smday,$shour,$smin,$ssec);
			my $tmpseries = sprintf("S%0.4dE%0.2d%0.2d%0.2d%0.2d%0.2d",($syear+1900),($smon+1),$smday,$shour,$smin,$ssec);
			$self->plexXML->dataElement('episode-num', $startdate, 'system' => 'original-air-date');
			$self->plexXML->dataElement('episode-num', $tmpseries, 'system' => 'SxxExx');
		}
		if (defined($items->{OriginalAirdate}))
		{
			my ($oadsec,$oadmin,$oadhour,$oadmday,$oadmon,$oadyear,$oadwday,$oadyday,$oadisdst) = localtime($items->{OriginalAirdate});
			$originalairdate = sprintf("%0.4d-%0.2d-%0.2d %0.2d:%0.2d:%0.2d",($oadyear+1900),$oadmon+1,$oadmday,$oadhour,$oadmin,$oadsec);
			$self->plexXML->dataElement('episode-num', $originalairdate, 'system' => 'original-air-date');
			$self->plexXML->emptyTag('previously-shown', 'start' => $originalairdate);
		} else {
			$self->plexXML->emptyTag('previously-shown');
		}
		$self->plexXML->endTag('programme');
	}
}

1;
