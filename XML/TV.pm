# XML::TV

package XML::TV;

use strict;
use warnings;
use diagnostics;

use vars qw($VERSION);

use Data::Dumper;

my $VERSION = sprintf("%d.%d.%d.%d.%d.%d", q$Id: TV.pm 700 2019-05-29 15:32:08Z  $ =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)Z/);

sub new
{
	my $class = shift;
	my $self = {};
	bless $self;

	my %arg = @_;

	#XML::TV->new( Source => 'Freeview', Country => 'Australia', Region => 'Sydney' );
	$self->debug(exists $arg{Debug} ? $arg{Debug} : undef);
	$self->pretty(exists $arg{Pretty} ? $arg{Pretty} : undef);
	$self->verbose(exists $arg{Verbose} ? $arg{Verbose} : undef);
	$self->source(exists $arg{Source} ? $arg{Source} : undef);
	$self->country(exists $arg{Country} ? $arg{Country} : undef);
	$self->region(exists $arg{Region} ? $arg{Region} : undef);

	$self->output(exists $arg{Output} ? $arg{Output} : 'stdout'); # file or stdout
	$self->filename(exists $arg{Filename} ? $arg{Filename} : undef);
	$self->format(exists $arg{Format} ? $arg{Format} : 'xmltv'); # xmltv (plex compatible), json, anything else?
	
	return $self;
}

sub debug
{
	my $self = shift;
	if (@_) {$self->{DEBUG} = $_[0]};
	$self->{DEBUG} = undef if (!defined $self->{DEBUG});
	return $self->{DEBUG};
}

sub pretty
{
	my $self = shift;
	if (@_) {$self->{PRETTY} = $_[0]};
	$self->{PRETTY} = undef if (!defined $self->{PRETTY});
	return $self->{PRETTY};
}

sub verbose
{
	my $self = shift;
	if (@_) {$self->{VERBOSE} = $_[0]};
	$self->{VERBOSE} = undef if (!defined $self->{VERBOSE});
	return $self->{VERBOSE};
}

sub source
{
	my $self = shift;
	if (@_) {$self->{SOURCE} = $_[0]};
	$self->{SOURCE} = undef if (!defined $self->{SOURCE});
	return $self->{SOURCE};
}

# This holds the configured country.
# We use it to initialise the feed.
sub country
{
	my $self = shift;
	if (@_) {$self->{COUNTRY} = $_[0]};
	$self->{COUNTRY} = undef if (!defined $self->{COUNTRY});
	return $self->{COUNTRY};
}

sub region
{
	my $self = shift;
	if (@_) {$self->{REGION} = $_[0]};
	$self->{REGION} = undef if (!defined $self->{REGION});
	return $self->{REGION};
}

# if country is already set this will load the Regoin
# module and initialise it, region doesn't have to be
# set at this time, because the country will define what
# regions are actually valid.  Without the country
# it is unknown if there are regions or not.
sub feed
{
	my $self = shift;
	if (@_) {$self->{FEED} = $_[0]};
	$self->{FEED} = undef if (!defined $self->{FEED});
	$self->{FEED} = XML::TV::Region->new(
						Country	=> $self->country,
						Region	=> $self->region,
						Verbose	=> $self->verbose,
						Debug	=> $self->debug,
					     ) if (defined $self->country);
	return $self->{FEED};
}

sub output
{
	my $self = shift;
	if (@_) {$self->{OUTPUT} = $_[0]};
	$self->{OUTPUT} = undef if (!defined $self->{OUTPUT});
	return $self->{OUTPUT};
}

sub filename
{
	my $self = shift;
	if (@_) {$self->{FILENAME} = $_[0]};
	$self->{FILENAME} = undef if (!defined $self->{FILENAME});
	return $self->{FILENAME};
}

sub format
{
	my $self = shift;
	if (@_) {$self->{FORMAT} = $_[0]};
	$self->{FORMAT} = undef if (!defined $self->{FORMAT});
	return $self->{FORMAT};
}

sub _feed
{
	my $self = shift;
	if (@_) {$self->{_FEED} = $_[0]};
	$self->{_FEED} = XML::TV::Feed->new(Country => $self->country, Source => $self->source, Feed => $self->source) if (!defined $self->{_FEED});
	return $self->{_FEED};
}

sub _output
{
	my $self = shift;
	if (@_) {$self->{_OUTPUT} = $_[0]};
	$self->{_OUTPUT} = XML::TV::Output->new(Format => $self->format, Filename => $self->filename, Format => $self->format);
	return $self->{_OUTPUT};
}

1;
