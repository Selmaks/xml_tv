# XML::TV::Region

package XML::TV::Region;

use strict;
use warnings;
use diagnostics;

use vars qw($VERSION);

use Data::Dumper;

my $VERSION = sprintf("%d.%d.%d.%d.%d.%d", q$Id: Region.pm 700 2019-05-29 15:32:08Z  $ =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)Z/);

sub new
{
	my $class = shift;
	my $self = {};
	bless $self;

	my %arg = @_;

	$self->debug(exists $arg{Debug} ? $arg{Debug} : undef);
	$self->pretty(exists $arg{Pretty} ? $arg{Pretty} : undef);
	$self->verbose(exists $arg{Verbose} ? $arg{Verbose} : undef);
	$self->country(exists $arg{Country} ? $arg{Country} : undef);
	$self->region(exists $arg{Region} ? $arg{Region} : undef);

	return $self;
}

sub mapping
{
	my $self = shift;
	my $country = $self->country;
	return undef if (!defined $country);
	# This will return the the country/region/source mapping
	$self->region = XML::TV::Region::$country->new();

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


1;
