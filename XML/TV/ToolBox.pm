# XML::TV::Toolbox

package XML::TV::Toolbox;

use strict;
use warnings;
use diagnostics;

use DateTime;
use DateTime::Duration;
use DateTime::TimeZone;

use vars qw($VERSION);

my $VERSION = sprintf("%d.%d.%d.%d.%d.%d", q$Id: Toolbox.pm 700 2019-05-29 15:32:08Z  $ =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)Z/);

sub new
{
	my $class = shift;
	my $self = {};
	bless $self;

	my %arg = @_;

	$self->debug(exists $arg{Debug} ? $arg{Debug} : undef);
	$self->verbose(exists $arg{Verbose} ? $arg{Verbose} : undef);
	# This will cause self initialisation on ->new()
	$self->ua(exists $arg{UA} ? $arg{UA} : undef);

	return $self;
}

sub ua
{
	my $self = shift;
	# if we were given one use that..
	if (@_) {$self->{UA} = $_[0]};
	# otherwise inialisae what we can find. (Default: Furl)
	$self->{UA} = $self->furl if (!defined $self->{UA});
	$self->{UA} = $self->lwp if (!defined $self->{UA});
	# Add any more you want to try here...
	die "FATAL: No User Agent Library present/usable.  Please install a working User Agent (eg. Furl or LWP)" if (!defined $self->{UA});
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

sub furl
{
	my $self = shift;
	my $ret = undef;
	$ret = eval 'use Furl; 1';
	if ($ret)
	{
		warn("XML::TV::Toolbox Using Furl for https:// fetch operations\n") if ($self->debug);
		$ret = Furl->new(
					agent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0',
					timeout => 30,
					headers => [ 'Accept-Encoding' => 'application/json', 'Accept-Charset' => 'utf-8' ],
					ssl_opts => {SSL_verify_mode => 0}
				);
	}
	return $ret
}

sub lwp
{
	my $self = shift;
	my $ret = eval 'use LWP::UserAgent; 1';
	if ($ret)
	{
		warn("XML::TV::Toolbox Using LWP::UserAgent for https:// fetch operations.\n") if ($self->debug);
		$ret = LWP::UserAgent->new;
		$ret->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0");
		$ret->default_header( 'Accept-Encoding' => 'application/json');
		$ret->default_header( 'Accept-Charset' => 'utf-8');
	}
	return $ret;
}

sub sanitizeText
{
	my $t = shift;
	$t =~ s/([$chars])/$map{$1}/g;
	$t =~ s/[^\040-\176]/ /g;
	return $t;
}

sub toLocalTimeString
{
	my $self = shift;
	my ($fulldate, $result_timezone) = @_;
	my ($year, $month, $day, $hour, $min, $sec, $offset) = $fulldate =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)(.*)/;#S$1E$2$3$4$5$6$7/;
	my ($houroffset, $minoffset);

	if ($offset =~ /z/i)
	{
		$offset = 0;
		$houroffset = 0;
		$minoffset = 0;
	}
	else
	{
		($houroffset, $minoffset) = $offset =~ /(\d+):(\d+)/;
	}
	my $dt = DateTime->new(
			year		=> $year,
			month		=> $month,
			day		=> $day,
			hour		=> $hour,
			minute		=> $min,
			second		=> $sec,
			nanosecond	=> 0,
			time_zone	=> $offset,
		);
	$dt->set_time_zone(  $result_timezone );
	my $tz = DateTime::TimeZone->new( name => $result_timezone );
	my $localoffset = $tz->offset_for_datetime($dt);
	$localoffset = $localoffset/3600;
	if ($localoffset =~ /\./)
	{
		$localoffset =~ s/(.*)(\..*)/$1$2/;
		$localoffset = sprintf("+%0.2d:%0.2d", $1, ($2*60));
	} else {
		$localoffset = sprintf("+%0.2d:00", $localoffset);
	}
	my $ymd = $dt->ymd;
	my $hms = $dt->hms;
	my $returntime = $ymd . "T" . $hms . $localoffset;
	return $returntime;
}

sub addTime
{
	my $self = shift;
	my ($duration, $startTime) = @_;
	my ($year, $month, $day, $hour, $min, $sec, $offset) = $startTime =~ /(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)(.*)/;#S$1E$2$3$4$5$6$7/;
		my $dt = DateTime->new(
			year		=> $year,
			month		=> $month,
			day		=> $day,
			hour		=> $hour,
			minute		=> $min,
			second		=> $sec,
			nanosecond	=> 0,
			time_zone	=> $offset,
		);
	my $endTime = $dt + DateTime::Duration->new( minutes => $duration );
	my $ymd = $endTime->ymd;
	my $hms = $endTime->hms;
	my $returntime = $ymd . "T" . $hms . $offset;
	return ($returntime);
}

sub getTimeOffset
{
	my $self = shift;
	my ($timezone, $time, $day) = @_;
	my $dtc = DateTime->now(time_zone => $timezone); # create a new object in the timezone
	my $dto = $dtc->clone; #DateTime->now(time_zone => $timezone); # create a new object in the timezone
	#$dtc->now; # from_epoch(time())
	#$dtc->time_zone($timezone); # set where we are working
	my ($hour, $minute, $ampm) = $time =~ /^(\d+):(\d+)\s+(AM|PM)$/; # split it up
	$dto->set_hour($hour);
	# add 12 hours if PM and anything but 12 noon - 12:59pm (as this would push it into tomorrow)
	$dto->add(hours => 12) if ($ampm eq "PM" and $hour ne 12);
	$dto->add(days => 1) if ($day eq "tomorrow");
	$dto->set_minute($minute);
	$dto->set_second("00");
	# add 12 hours if PM
	my $duration = ($dto->epoch)-($dtc->epoch);
	warn($dtc . " - " . $dto . "\n") if ($DEBUG);
	warn($time . " --> " . $dtc->epoch . "-" . $dto->epoch . " = $duration\n") if ($DEBUG);
	return $duration; # should be seconds (negative if before 'now')
}

sub get_duplicate_channels
{
	my $self = shift;
	my @duplicates = ();
	foreach my $dupe (@_)
	{
		my ($original, $dupes) = split(/=/, $dupe);
		if (!defined $dupes || !length $dupes)
		{
			warn("WARNING: Ignoring --duplicate $dupe as it is not in the correct format (should be: --duplicate 6=60,61)\n");
			next;
		}
		my @channels = split(/,/, $dupes);
		if (!@channels || !scalar @channels)
		{
			warn("WARNING: Ignoring --duplicate $dupe as it is not in the correct format (should be: --duplicate 6=60,61,... etc)\n");
			next;
		}
		push(@duplicates, $original);
		foreach my $channel (@channels)
		{
			$duplicates{$channel} = $original;
		}
	}
	return @duplicates;
}

1;
