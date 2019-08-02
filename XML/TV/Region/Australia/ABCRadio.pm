# XML::TV::Region::Australia

package XML::TV::Region::Australia::ABCRadio;

use strict;
use warnings;
use diagnostics;

use vars qw($VERSION);

use parent -norequire, 'Australia';

use JSON;
use XML::TV::Toolbox;
#use Data::Dumper;

my $VERSION = sprintf("%d.%d.%d.%d.%d.%d", q$Id: ABCRadio.pm 700 2019-05-29 15:32:08Z  $ =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)Z/);

# This is not meant to be called directly by the user, it's called
# by Australia.pm (or any other region, but that's highly unlikely
# being that it's region specificness.)

my %ABCRADIO = (
		200 => (
			name		=> "Double J",
			iconurl		=> "https://www.abc.net.au/cm/lb/8811932/thumbnail/station-logo-thumbnail.jpg",
			servicename	=> "doublej",
		       ),
		201 => (
			name		=> "ABC Jazz",
			iconurl		=> "https://www.abc.net.au/cm/lb/8785730/thumbnail/station-logo-thumbnail.png",
			servicename	=> "jazz",
		       ),
		);

sub new
{
	my $class = shift;
	my $self = {};
	bless $self;

	my %arg = @_;

#	$self->debug(exists $arg{Debug} ? $arg{Debug} : undef);
#	$self->verbose(exists $arg{Verbose} ? $arg{Verbose} : undef);
#	$self->toolbox(exists $arg{ToolBox} ? $arg{ToolBox} : XML::TV::Toolbox->new(Debug => $self->debug, Verbose => $self->verbose);
#	# If we are passed a useragent use it, otherwise initialise a new one
#	$self->ua(exists $arg{UA} ? $arg{UA} : $self->toolbox->ua;

	return $self;
}

sub getchannels
{
	my $self = shift;
	my @data;
	foreach my $key (keys %ABCRADIO)
	{
		warn("Getting channels for $ABCRADIO{$key}{name} ...\n") if ($self->verbose);
		my $chan = {
				name	=> $ABCRADIO{$key}{name},
				id	=> $key.".yourtv.com.au",
				lcn	=> $key,
				icon	=> $ABCRADIO{$key}{iconurl},
			   };
		push(@data, $chan);
	}
	return @data;
}

sub getepg
{
	my $self = shift;
	my ($ua, $numdays) = @_;
	my $showcount = 0;
	my @guidedata;
	foreach my $key (keys %ABCRADIO)
	{
		my $id = $key;
		warn("Getting epg for $ABCRADIO{$key}{name} ...\n") if ($self->verbose);
		my ($ssec,$smin,$shour,$smday,$smon,$syear,$swday,$syday,$sisdst) = localtime(time);
		my ($esec,$emin,$ehour,$emday,$emon,$eyear,$ewday,$eyday,$eisdst) = localtime(time+(86400*$numdays));
		my $startdate = sprintf("%0.4d-%0.2d-%0.2dT%0.2d:%0.2d:%0.2dZ",($syear+1900),$smon+1,$smday,$shour,$smin,$ssec);
		my $enddate = sprintf("%0.4d-%0.2d-%0.2dT%0.2d:%0.2d:%0.2dZ",($eyear+1900),$emon+1,$emday,$ehour,$emin,$esec);

		my $url = URI->new( 'https://program.abcradio.net.au/api/v1/programitems/search.json' );
		$url->query_form(service => $ABCRADIO{$key}{servicename}, limit => '100', order => 'asc', order_by => 'ppe_date', from => $startdate, to => $enddate);
		my $res = $ua->get($url);
		warn("Getting channel program listing for $key ( $url )...\n") if ($self->verbose);
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
				my $show = {};
				$show->{id} = $key.".yourtv.com.au";
				$show->{start} = $tmpdata->[$count]->{live}[0]->{start};
				$show->{start} = $self->toolbox->toLocalTimeString($tmpdata->[$count]->{live}[0]->{start},'UTC');
				my $duration = $tmpdata->[$count]->{live}[0]->{duration_seconds}/60;
				$show->{stop} = $self->toolbox->addTime($duration,$guidedata[$showcount]->{start});
				$show->{start} =~ s/[-T:]//g;
				$show->{start} =~ s/\+/ \+/g;
				$show->{stop} =~ s/[-T:]//g;
				$show->{stop} =~ s/\+/ \+/g;

				$show->{channel} = $ABCRADIO{$key}{name};
				$show->{title} = $tmpdata->[$count]->{title};
				my $catcount = 0;
				push(@{$show->{category}}, "Radio");
				foreach my $tmpcat (@{$tmpdata->[$count]->{categories}})
				{
					push(@{$show->{category}}, $tmpcat->{label});
					$catcount++; # why do you need this?
				}
				$show->{desc} = $tmpdata->[$count]->{short_sypnosis};
				push(@guidedata, $show);
			}
		}

	}
	warn("Processed a totol of " . scalar @guidedata . " shows ...\n") if ($self->verbose);
	return @guidedata;
}

#sub ua
#{
#	my $self = shift;
#	if (@_) {$self->{UA} = $_[0]};
#	$self->{UA} = undef if (!defined $self->{UA});
#	return $self->{UA};
#}
#
#sub debug
#{
#	my $self = shift;
#	if (@_) {$self->{DEBUG} = $_[0]};
#	$self->{DEBUG} = undef if (!defined $self->{DEBUG});
#	return $self->{DEBUG};
#}
#
#sub verbose
#{
#	my $self = shift;
#	if (@_) {$self->{VERBOSE} = $_[0]};
#	$self->{VERBOSE} = undef if (!defined $self->{VERBOSE});
#	return $self->{VERBOSE};
#}
#
#sub toolbox
#{
#	my $self = shift;
#	if (@_) {$self->{TOOLBOX} = $_[0]};
#	$self->{TOOLBOX} = XML::TV::Toolbox->new(Debug => $self->debug, Verbose => $self->verbose) if (!defined $self->{TOOLBOX});
#	return $self->{TOOLBOX};
#}

1;
