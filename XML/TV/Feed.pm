# XML::TV:Feed

package XML::TV:Feed;

use strict;
use warnings;
use diagnostics;

use vars qw($VERSION);

use Data::Dumper;

my $VERSION = sprintf("%d.%d.%d.%d.%d.%d", q$Id: PD.pm 700 2019-05-29 15:32:08Z  $ =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)Z/);

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

# source will load the object for each source (if it's there)
sub source
{
	my $self = shift;
	$self->{_FEED}->{$_[0]} = XML::TV::Feed::$_[0]->new(Pretty => $self->pretty, Debug => $self->debug, Verbose => $self->verbose) if (!defined $self->{_FEED}->{$_[0]});
	return $self->{_FEED}->{$_[0]};
}

sub country
{
	my $self = shift;
	if (@_) {$self->{COUNTRY} = $_[0]};
	$self->{COUNTRY} = undef if (!defined $self->{COUNTRY});
	return $self->{COUNTRY};
}

sub feed
{
	my $self = shift;
	if (@_) {$self->{FEED} = $_[0]};
	$self->{FEED} = undef if (!defined $self->{FEED});
	return $self->{FEED};
}

sub _feed
{
	my $self = shift;
	if (@_) {$self->{_FEED} = $_[0]};
	$self->{_FEED} = XML::TV::Feed->new(Country => $self->country, Source => $self->source, Feed => $self->source) if (!defined $self->{_FEED});
	return $self->{_FEED};
}

1;
