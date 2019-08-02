# XML::TV::Region::Australia

package XML::TV::Region::Australia;

use strict;
use warnings;
use diagnostics;

use vars qw($VERSION);

use JSON;
use XML::TV::Toolbox;
#use Data::Dumper;

my $VERSION = sprintf("%d.%d.%d.%d.%d.%d", q$Id: Australia.pm 700 2019-05-29 15:32:08Z  $ =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)Z/);

sub new
{
	my $class = shift;
	my $self = {};
	bless $self;

	my %arg = @_;

	$self->debug(exists $arg{Debug} ? $arg{Debug} : undef);
	$self->verbose(exists $arg{Verbose} ? $arg{Verbose} : undef);
	$self->region(exists $arg{Region} ? $arg{Region} : undef);
	# If we are passed a useragent use it, otherwise initialise a new one
	$self->ua(exists $arg{UA} ? $arg{UA} : XML::TV::Toolbox->new(Debug => $self->debug, Verbose => $self->verbose);

	return $self;
}

sub checkRegion
{
	my $valid = 0;
	foreach my $r ( $self->regions )
	{
		if ($r->{id} eq $self->region)
		{
			$valid++;
			$self->timezone($r->{timezone});
			$self->name($r->{name});
		}
	}

	die(      "\n"
		. "Invalid region specified.  Please use one of the following:\n\t\t"
		. join("\n\t\t", (map { "$_->{id}\t=\t$_->{name}" } $self->regions) )
		. "\n\n"
	   ) if (!$valid);
	return $valid;
}

# this just builds the regions array and is called as soon as the region is set
sub buildRegions
{
	my $url = "https://www.yourtv.com.au/guide/";
	warn("XML::TV::Region::Australia fetching region list from: $url\n") if ($self->verbose);
	my $res = $ua->get($url);
	die("Unable to connect to $url.\n") if (!$res->is_success);
	my $data = $res->content;
	$data =~ s/\R//g;
	$data =~ s/.*window.regionState\s+=\s+(\[.*\]);.*/$1/;
	$self->regions(@{JSON->new->relaxed(1)->allow_nonref(1)->decode($data)});
}

# this should probably go into the parent..
# the feed can contain 'Radio', 'TV' or 'Radio & TV' or 'Radio+TV' etc
sub skip_type
{
	my $self = shift;
	my $feed = shift;
	my $feeds = %{$self->feeds};
	my $skip = 0;
	$skip++ if ($feeds{$feed} =~ /Radio/ && !$self->radio);
	$skip++ if ($feeds{$feed} =~ /TV/ && !$self->tv);
	return $skip;
}

sub getchannels
{
	my $self = shift;
	my @channels = ();
	my %feeds = %{$self->feeds};
	foreach my $feed (keys %feeds)
	{
		next if ($self->skip_type($feed));
		my $obj = $feed->new();
		push(@channels, $obj->getchannels());
	}
	return @channels;
}

sub getepg
{
	my $self = shift;
	my @epg = ();
	my %feeds = %{$self->feeds};
	foreach my $feed (keys %feeds)
	{
		next if ($self->skip_type($feed));
		my $obj = $feed->new();
		push(@epg, $obj->getepg());
	}
	return @epg;
}

# very simple return to get an array of modules used for the feeds
sub feeds
{
	my %feeds = (
			"XML::TV::Region::Australia::YourTV" => "TV",
			"XML::TV::Region::Australia::ABCRadio" => "Radio",
			"XML::TV::Region::Australia::SBSRadio" => "Radio",
		    );
	return \%feeds;
	#return("Australia::YourTV", "Australia::ABCRadio", "Australia::SBSRadio");
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

sub regions
{
	my $self = shift;
	if (@_) {$self->{REGIONS} = $_[0]};
	$self->{REGIONS} = $self->buildRegions if (!defined $self->{REGIONS});
	return $self->{REGIONS};
}

sub region
{
	my $self = shift;
	if (@_)
	{
		if ($self->checkRegion($_[0]))
		{
			$self->{REGION} = $_[0];
		}
	}
	$self->{REGION} = undef if (!defined $self->{REGIONS});
	return $self->{REGION};
}

sub name
{
	my $self = shift;
	if (@_) {$self->{NAME} = $_[0]};
	$self->{NAME} = undef if (!defined $self->{NAME});
	return $self->{NAME};
}

sub timezone
{
	my $self = shift;
	if (@_) {$self->{TIMEZONE} = $_[0]};
	$self->{TIMEZONE} = undef if (!defined $self->{TIMEZONE});
	return $self->{TIMEZONE};
}

1;
