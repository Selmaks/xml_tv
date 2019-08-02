# XML::TV::Region::Australia::YourTV

package XML::TV::Region::Australia::YourTV;

use strict;
use warnings;
use diagnostics;

use vars qw($VERSION);

use parent -norequire, 'Australia';

use JSON;
use XML::TV::Toolbox;
#use Data::Dumper;

my $VERSION = sprintf("%d.%d.%d.%d.%d.%d", q$Id: YourTV.pm 700 2019-05-29 15:32:08Z  $ =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)Z/);

# This is not meant to be called directly by the user, it's called
# by Australia.pm (or any other region, but that's highly unlikely
# being that it's region specificness.)
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
	my $region = shift;
	warn("Getting channel list from YourTV ...\n") if ($self->verbose);
	my $url = "https://www.yourtv.com.au/api/regions/$region/channels";
	my $res = $self->ua->get($url);
	die("Unable to connect to YourTV.\n") if (!$res->is_success);

	my @chandata = ();
	my @dupechans = ();

	my $tmpchandata = JSON->new->relaxed(1)->allow_nonref(1)->decode($res->content);
	for (my $count = 0; $count < @$chandata; $count++)
	{
		next if ( ( grep( /^$tmpchandata->[$count]->{id}$/, @IGNORECHANNELS ) ) );
		next if ( ( !( grep( /^$tmpchandata->[$count]->{number}$/, @INCLUDECHANNELS ) ) ) and ( ( @INCLUDECHANNELS > 0 ) ) );
		my $channelIsDuped = 0;
		++$channelIsDuped if ( ( grep( /$tmpchandata->[$count]->{number}$/, @DUPLICATED_CHANNELS ) ) );
		my $chan = {};
		$chan->{tv_id} = $tmpchandata->[$count]->{id};
		$chan->{name} = $tmpchandata->[$count]->{description};
		$chan->{id} = $tmpchandata->[$count]->{number}.".yourtv.com.au";
		$chan->{lcn} = $tmpchandata->[$count]->{number};
		$chan->{icon} = $tmpchandata->[$count]->{logo}->{url};
		$chan->{icon} = $FVICONS->{$tmpchandata->[$count]->{number}} if (defined($FVICONS->{$tmpchandata->[$count]->{number}}));
		# FIX SBS Icons
		if (($usefreeviewicons) && (!defined($CHANNELDATA[$count]->{icon})) && ($CHANNELDATA[$count]->{name} =~ /SBS/))
		{
			$tmpchandata->[$count]->{number} =~ s/(\d)./$1/;
			$chan->{icon} = $FVICONS->{$tmpchandata->[$count]->{number}} if (defined($FVICONS->{$tmpchandata->[$count]->{number}}));
		}
		warn("Got channel $chan->{id} - $chan->{name} ...\n") if ($self->verbose);
		push(@chandata, $chan);
		if ($channelIsDuped)
		{
			foreach my $dchan (sort keys %DUPLICATE_CHANNELS)
			{
				next if ($DUPLICATE_CHANNELS{$dchan} ne $tmpchandata->[$count]->{number});
				my $dupechan = {};
				$dupechan->{tv_id} = $chan->{tv_id};
				$dupechan->{name} = $chan->{name};
				$dupechan->{id} = $dchan . ".yourtv.com.au";
				$dupechan->{lcn} = $dchan;
				$dupechan->{icon} = $chan->{icon};
				warn("Duplicated channel $chan->{name} -> $dupechan->{id} ...\n") if ($self->verbose);
				push(@dupechans, $dupechan);
			}
		}
	}
	return (@chandata, @dupechans);
}

sub getepg
{
	my $self = shift;
	my $showcount = 0;
	my $dupe_scount = 0;
	my $url;

	warn(" \n") if ($self->verbose);
	my $nl = 0;
	my @shows = ();

	for(my $day = 0; $day < $NUMDAYS; $day++)
	{
		my $day = nextday($day);
		my $id;
		my $url = URI->new( 'https://www.yourtv.com.au/api/guide/' );
		$url->query_form(day => $day, timezone => $REGION_TIMEZONE, format => 'json', region => $REGION);
		warn(($nl ? "\n" : "" ) . "Getting channel program listing for $REGION_NAME ($REGION) for $day ($url)...\n") if ($self->verbose);
		$nl = 0;
		my $res = $self->ua->get($url);
		die("Unable to connect to YourTV for $url.\n") if (!$res->is_success);
		my $tmpdata;
		eval
		{
			$tmpdata = JSON->new->relaxed(1)->allow_nonref(1)->decode($res->content);
			1;
		};
		my $chandata = $tmpdata->[0]->{channels};
		if (defined($chandata))
		{
			for (my $channelcount = 0; $channelcount < @$chandata; $channelcount++)
			{
				next if (!defined($chandata->[$channelcount]->{number}));
				next if ( ( grep( /^$chandata->[$channelcount]->{number}$/, @IGNORECHANNELS ) ) );
				next if ( ( !( grep( /^$chandata->[$channelcount]->{number}$/, @INCLUDECHANNELS ) ) ) and ((@INCLUDECHANNELS > 0)));
				my $channelIsDuped = 0;
				$channelIsDuped = $chandata->[$channelcount]->{number} if ( ( grep( /^$chandata->[$channelcount]->{number}$/, @DUPLICATED_CHANNELS ) ) );

				my $enqueued = 0;
				$id = $chandata->[$channelcount]->{number}.".yourtv.com.au";
				my $blocks = $chandata->[$channelcount]->{blocks};
				for (my $blockcount = 0; $blockcount < @$blocks; $blockcount++)
				{
					my $subblocks = $blocks->[$blockcount]->{shows};
					for (my $airingcount = 0; $airingcount < @$subblocks; $airingcount++)
					{
						warn("Starting... ($blockcount < " . scalar @$blocks . "| $airingcount < " . scalar @$subblocks . ")\n") if ($self->debug);
						my $airing = $subblocks->[$airingcount]->{id};
						warn("Starting $airing...\n") if ($self->debug);
						# We don't use the cache for 'today' incase of any last minute programming changes
						#
						# but if cachetime is set, work out if we use the cache or not. (Advanced users only)
						if (!exists $dbm_hash{$airing} || $dbm_hash{$airing} eq "$airing|undef")
						{
							warn("No cache data for $airing, requesting...\n") if ($self->debug);
							$INQ->enqueue($airing);
							++$enqueued; # Keep track of how many fetches we do
						} else {
							my $usecache = 1; # default is to use the cache
							$usecache = 0 if ($CACHETIME eq 86400 && ($day eq "today" || $day eq "tomorrow")); # anything today is not cached if default cachetime
							if ($usecache && $CACHETIME ne 86400)
							if ($usecache && $CACHETIME ne 86400)
							{
								if ($day eq "today" || $day eq "tomorrow")
								{
									# CACHETIME is non default so more complicated
									# so we just need to know if the airing is within our cachetime
									# however at this level the aring has just things like "5:30 AM" or "6:00 PM"
									# so we need to do some conversions
									my $offset = $self->toolbox->getTimeOffset($REGION_TIMEZONE, $subblocks->[$airingcount]->{date}, $day);
									warn("Checking $offset against $CACHETIME\n") if ($self->debug);
									$usecache = 0 if (abs($offset) eq $offset && $CACHETIME > $offset);
								}
							}
							if (!$usecache)
							{
								warn("Cache Data is within the last $CACHETIME seconds, ignoring cache data for $airing, requesting...[" . $subblocks->[$airingcount]->{date} . "]\n") if ($self->debug);
								$INQ->enqueue($airing);
								++$enqueued; # Keep track of how many fetches we do
							} else {
								# we can use the cache...
								warn("Using cache for $airing.\n") if ($self->debug && $day eq "today");
								my $data = $dbm_hash{$airing};
								warn("Got cache data for $airing.\n") if ($self->debug);
								$thrdret{$airing} = $data;
								warn("Wrote cache data for $airing.\n") if ($self->debug);
							}
						}
						warn("Done $airing...\n") if ($self->debug);
					}
				}
				for (my $l = 0;$l < $enqueued; ++$l)
				{
					# At this point all the threads should have all the URLs in the queue and
					# will resolve them independently - this means they will not necessarily
					# be in the right order when we get them back.  That said, because we will
					# reuse these threads and queues on each loop we wait here to get back
					# all the results before we continue.
					my ($airing, $result) = split(/\|/, $OUTQ->dequeue(), 2);
					warn("$airing = $result\n") if ($self->debug);
					$thrdret{$airing} = $result;
				}
				if ($self->verbose && $enqueued)
				{
					local $| = 1;
					print " ";
					$nl++;
				}
				for (my $blockcount = 0; $blockcount < @$blocks; $blockcount++)
				{
					my $subblocks = $blocks->[$blockcount]->{shows};
					#for (my $airingcount = 0; $airingcount < @$subblocks; $airingcount++)
					#{
					#       my ($airing, $result) = split(/\|/, $OUTQ->dequeue(), 2);
					#       warn("$airing = $result\n") if ($self->debug);
					#       $thrdret{$airing} = $result;
					#}
					# Here we will have all the returned data in the hash %thrdret with the
					# url as the key.
					for (my $airingcount = 0; $airingcount < @$subblocks; $airingcount++)
					{
						my $showdata;
						my $airing = $subblocks->[$airingcount]->{id};
						if ($thrdret{$airing} eq "FAILED")
						{
							warn("Unable to connect to YourTV for https://www.yourtv.com.au/api/airings/$airing ... skipping\n");
							next;
						} elsif ($thrdret{$airing} eq "ERROR") {
							die("FATAL: Unable to connect to YourTV for https://www.yourtv.com.au/api/airings/$airing ... (error code >= 500 have you need banned?)\n");
						} elsif ($thrdret{$airing} eq "UNKNOWN") {
							die("FATAL: Unable to connect to YourTV for https://www.yourtv.com.au/api/airings/$airing ... (Unknown Error!)\n");
						}
						eval
						{
							$showdata = JSON->new->relaxed(1)->allow_nonref(1)->decode($thrdret{$airing});
							1;
						};
						if (defined($showdata))
						{
							my $guidedata = {};
							$guidedata->{id} = $id;
							$guidedata->{airing_tmp} = $airing;
							$guidedata->{desc} = $showdata->{synopsis};
							$guidedata->{subtitle} = $showdata->{episodeTitle};
							$guidedata->{start} = $self->toolbox->toLocalTimeString($showdata->{date},$REGION_TIMEZONE);
							$guidedata->{stop} = $self->toolbox->addTime($showdata->{duration},$guidedata->{start});
							$guidedata->{start} =~ s/[-T:]//g;
							$guidedata->{start} =~ s/\+/ \+/g;
							$guidedata->{stop} =~ s/[-T:]//g;
							$guidedata->{stop} =~ s/\+/ \+/g;
							$guidedata->{channel} = $showdata->{service}->{description};
							$guidedata->{title} = $showdata->{title};
							$guidedata->{rating} = $showdata->{classification};
							if (defined($showdata->{program}->{image}))
							{
								$guidedata->{url} = $showdata->{program}->{image};
							} else {
								if (defined($FVICONURL->{$chandata->[$channelcount]->{number}}->{$guidedata->{title}}))
								{
									$guidedata->{url} = $FVICONURL->{$chandata->[$channelcount]->{number}}->{$guidedata->{title}}
								} else {
									$guidedata->{url} = getFVShowIcon($chandata->[$channelcount]->{number},$guidedata->{title},$guidedata->{start},$guidedata->{stop})
								}
							}
							push(@{$guidedata->{category}}, $showdata->{genre}->{name});
							#       program types as defined by yourtv $showdata->{programType}->{id}
							#       1	Television movie
							#       2	Cinema movie
							#       3	Mini series
							#       4	Series no episodes
							#       5	Series with episodes
							#       8	Limited series
							#       9	Special
							my $tmpseries = $self->toolbox->toLocalTimeString($showdata->{date},$REGION_TIMEZONE);
							my ($episodeYear, $episodeMonth, $episodeDay, $episodeHour, $episodeMinute) = $tmpseries =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+).*/;#S$1E$2$3$4$5/;

							#if ($showdata->{programType}->{id} eq "1") {
							if ($showdata->{program}->{programTypeId} eq "1")
							{
								push(@{$guidedata->{category}}, $showdata->{programType}->{name});
							} elsif ($showdata->{program}->{programTypeId} eq "2") {
								push(@{$guidedata->{category}}, $showdata->{programType}->{name});
							} elsif ($showdata->{program}->{programTypeId} eq "3") {
								push(@{$guidedata->{category}}, $showdata->{programType}->{name});
								$guidedata->{episode} = $showdata->{episodeNumber} if (defined($showdata->{episodeNumber}));
								$guidedata->{season} = "1";
							} elsif ($showdata->{program}->{programTypeId} eq "4") {
								$guidedata->{premiere} = "1";
								$guidedata->{originalairdate} = $episodeYear."-".$episodeMonth."-".$episodeDay." ".$episodeHour.":".$episodeMinute.":00";#"$1-$2-$3 $4:$5:00";
								if (defined($showdata->{episodeNumber}))
								{
									$guidedata->{episode} = $showdata->{episodeNumber};
								} else {
									$guidedata->{episode} = sprintf("%0.2d%0.2d",$episodeMonth,$episodeDay);
								}
								if (defined($showdata->{seriesNumber}))
								{
									$guidedata->{season} = $showdata->{seriesNumber};
								} else {
									$guidedata->{season} = $episodeYear;
								}
							} elsif ($showdata->{program}->{programTypeId} eq "5") {
								if (defined($showdata->{seriesNumber}))
								{
									$guidedata->{season} = $showdata->{seriesNumber};
								} else {
									$guidedata->{season} = $episodeYear;
								}
								if (defined($showdata->{episodeNumber}))
								{
									$guidedata->{episode} = $showdata->{episodeNumber};
								} else {
									$guidedata->{episode} = sprintf("%0.2d%0.2d",$episodeMonth,$episodeDay);
								}
							} elsif ($showdata->{program}->{programTypeId} eq "8") {
								if (defined($showdata->{seriesNumber}))
								{
									$guidedata->{season} = $showdata->{seriesNumber};
								} else {
									$guidedata->{season} = $episodeYear;
								}
								if (defined($showdata->{episodeNumber}))
								{
									$guidedata->{episode} = $showdata->{episodeNumber};
								} else {
									$guidedata->{episode} = sprintf("%0.2d%0.2d",$episodeMonth,$episodeDay);
								}
							} elsif ($showdata->{program}->{programTypeId} eq "9") {
								$guidedata->{season} = $episodeYear;
								$guidedata->{episode} = sprintf("%0.2d%0.2d",$episodeMonth,$episodeDay);
							}
							if (defined($showdata->{repeat} ) )
							{
								$guidedata->{originalairdate} = $episodeYear."-".$episodeMonth."-".$episodeDay." ".$episodeHour.":".$episodeMinute.":00";#"$1-$2-$3 $4:$5:00";
								$guidedata->{previouslyshown} = "$episodeYear-$episodeMonth-$episodeDay";#"$1-$2-$3";
							}
							push(@shows, $guidedata)
							if ($channelIsDuped)
							{
								foreach my $dchan (sort keys %DUPLICATE_CHANNELS)
								{
									next if ($DUPLICATE_CHANNELS{$dchan} ne $channelIsDuped);
									my $did = $dchan . ".yourtv.com.au";
									my $dupeguidedata = {};
									$dupeguidedata = clone($guidedata);
									$dupeguidedata->{id} = $did;
									$dupeguidedata->{channel} = $did;
									warn("Duplicated guide data for show entry $showcount -> $dupe_scount ($guidedata -> $dupeguidedata) ...\n") if ($self->debug);
									push(@shows, $dupeguidedata);
								}
							}
							$showcount++;
						}
					}
				}
			}
		}
	}
	warn("Processed a total of " . scalar @showdata . " shows ...\n") if ($self->verbose);
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
