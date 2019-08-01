# XML::TV::Toolbox

package XML::TV::Toolbox;

use strict;
use warnings;
use diagnostics;

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

1;
