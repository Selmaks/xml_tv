# XML::TV::Region::Australia

package XML::TV::Region::Australia::SBSRadio;

use strict;
use warnings;
use diagnostics;

use vars qw($VERSION);

use parent -norequire, 'Australia';

use JSON;
use XML::TV::Toolbox;
#use Data::Dumper;

my $VERSION = sprintf("%d.%d.%d.%d.%d.%d", q$Id: SBSRadio.pm 700 2019-05-29 15:32:08Z  $ =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)Z/);

# This is not meant to be called directly by the user, it's called
# by Australia.pm (or any other region, but that's highly unlikely
# being that it's region specificness.)

# These are australia wide so can be defined statically
my $SBSRADIO = (
		36 => (
			name		=> "SBS Arabic24",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbsarabic24_300_colour.png",
			servicename	=> "poparaby",
		      ),
		37 => (
			name		=> "SBS Radio 1",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbs1_300_colour.png",
			servicename	=> "poparaby",
		      ),
		38 => (
			name		=> "SBS Radio 2",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbs2_300_colour.png",
			servicename	=> "poparaby",
		      ),
		39 => (
			name		=> "SBS Chill",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/header_chill_300_colour.png",
			servicename	=> "poparaby",
		      ),
		301 => (
			name		=> "SBS Radio 1",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbs1_300_colour.png",
			servicename	=> "poparaby",
		      ),
		302 => (
			name		=> "SBS Radio 2",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbs2_300_colour.png",
			servicename	=> "poparaby",
		      ),
		303 => (
			name		=> "SBS Radio 3",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbs3_300_colour.png",
			servicename	=> "poparaby",
		      ),
		304 => (
			name		=> "SBS Arabic24",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/headerlogo_sbsarabic24_300_colour.png",
			servicename	=> "poparaby",
		      ),
		305 => (
			name		=> "SBS PopDesi",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/header_popdesi_300_colour.png",
			servicename	=> "poparaby",
		      ),
		306 => (
			name		=> "SBS Chill",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/header_chill_300_colour.png",
			servicename	=> "poparaby",
		      ),
		307 => (
			name		=> "SBS PopAsia",
			iconurl		=> "http://d6ksarnvtkr11.cloudfront.net/resources/sbs/radio/images/header_popasia_300_colour.png",
			servicename	=> "poparaby",
		      ),
		);
		
sub new
{
	my $class = shift;
	my $self = {};
	bless $self;

	my %arg = @_;

	$self->debug(exists $arg{Debug} ? $arg{Debug} : undef);
	$self->verbose(exists $arg{Verbose} ? $arg{Verbose} : undef);
	$self->toolbox(exists $arg{ToolBox} ? $arg{ToolBox} : XML::TV::Toolbox->new(Debug => $self->debug, Verbose => $self->verbose);
	# If we are passed a useragent use it, otherwise initialise a new one
	$self->ua(exists $arg{UA} ? $arg{UA} : $self->toolbox->ua);

	return $self;
}

sub getchannels
{
	my $self = shift;
	my @data;
	foreach my $key (keys %SBSRADIO)
	{
		warn("Getting channels for $SBSRADIO{$key}{name} ...\n") if ($self->verbose);
		my $chan = {
				name	=> $SBSRADIO{$key}{name},
				id	=> $key.".yourtv.com.au",
				lcn	=> $key,
				icon	=> $SBSRADIO{$key}{iconurl},
			   };
		push(@data, $chan);
	}
	return @data;
}

sub getepg
{
	my $self = shift;
	my ($ua, $numdays) = @_;
	my @guidedata;
	foreach my $key (keys %SBSRADIO)
	{
		my $id = $key;
		warn("Getting epg for $SBSRADIO{$key}{name} ...\n") if ($self->verbose);
		my $now = time;
		my ($ssec,$smin,$shour,$smday,$smon,$syear,$swday,$syday,$sisdst) = localtime(time);
		my ($esec,$emin,$ehour,$emday,$emon,$eyear,$ewday,$eyday,$eisdst) = localtime(time+(86400*$numdays));
		my $startdate = sprintf("%0.4d-%0.2d-%0.2dT%0.2d:%0.2d:%0.2dZ",($syear+1900),$smon+1,$smday,$shour,$smin,$ssec);
		my $enddate = sprintf("%0.4d-%0.2d-%0.2dT%0.2d:%0.2d:%0.2dZ",($eyear+1900),$emon+1,$emday,$ehour,$emin,$esec);

		my $url = "http://two.aim-data.com/services/schedule/sbs/".$SBSRADIO{$key}{servicename}."?days=".$numdays;
		my $res = $ua->get($url);
		warn("Getting channel program listing for $key ( $url )...\n") if ($self->verbose);
		die("Unable to connect to SBS. [" . $res->status_line . "]\n") if (!$res->is_success);
		my $data = $res->content;
		my $tmpdata;
		eval {
			$tmpdata = XMLin($data);
			1;
		};
		$tmpdata = $tmpdata->{entry};
		if (defined($tmpdata))
		{
			foreach my $key (keys %$tmpdata)
			{
				my $show = {};
				$show->{id} = $id.".yourtv.com.au";
				$show->{start} = $tmpdata->{$key}->{start};
				$show->{start} =~ s/[-T:\s]//g;
				$show->{start} =~ s/(\+)/00 +/;
				$shot->{stop} = $tmpdata->{$key}->{end};
				$show->{stop} =~ s/[-T:\s]//g;
				$show->{stop} =~ s/(\+)/00 +/;
				$show->{channel} = $SBSRADIO{$key}{name};
				$show->{title} = $tmpdata->{$key}->{title};
				push(@{$show->{category}}, "Radio");
				my $desc = $tmpdata->{$key}->{description};
				$show->{desc} = $desc if (!(ref $desc eq ref {}));
				push(@guidedata, $show);
			}
		}
	}
	warn("Processed a totol of " . scalar @guidedata . " shows ...\n") if ($self->verbose);
	return @guidedata;
}

sub ua
{
	my $self = shift;
	if (@_) {$self->{UA} = $_[0]};
	$self->{UA} = undef if (!defined $self->{UA});
	return $self->{UA};
}

sub debug
{
	my $self = shift;
	if (@_) {$self->{DEBUG} = $_[0]};
	$self->{DEBUG} = undef if (!defined $self->{DEBUG});
	return $self->{DEBUG};
}

sub verbose
{
	my $self = shift;
	if (@_) {$self->{VERBOSE} = $_[0]};
	$self->{VERBOSE} = undef if (!defined $self->{VERBOSE});
	return $self->{VERBOSE};
}

sub toolbox
{
	my $self = shift;
	if (@_) {$self->{TOOLBOX} = $_[0]};
	$self->{TOOLBOX} = XML::TV::ToolBox->new(Debug => $self->debug, Verbose => $self->verbose) if (!defined $self->{TOOLBOX});
	return $self->{TOOLBOX};
}
1;
