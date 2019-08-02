# XML::TV::Output

package XML::TV::Output;

use strict;
use warnings;
use diagnostics;

use vars qw($VERSION);

use Data::Dumper;

# if we use this the debug/verbose etc will be inherited
use parent -norequire, 'TV';

my $VERSION = sprintf("%d.%d.%d.%d.%d.%d", q$Id: PD.pm 700 2019-05-29 15:32:08Z  $ =~ /(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)Z/);

sub new
{
	my $class = shift;
	my $self = {};
	bless $self;

	my %arg = @_;

#	$self->debug(exists $arg{Debug} ? $arg{Debug} : undef);
#	$self->pretty(exists $arg{Pretty} ? $arg{Pretty} : undef);
#	$self->verbose(exists $arg{Verbose} ? $arg{Verbose} : undef);

	$self->output(exists $arg{Output} ? $arg{Output} : 'stdout'); # file or stdout
	$self->filename(exists $arg{Filename} ? $arg{Filename} : undef);
	$self->format(exists $arg{Format} ? $arg{Format} : 'xmltv'); # xmltv (plex compatible), json, anything else?
	
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

sub output
{
	my $self = shift;
	if (@_) {$self->{OUTPUT} = $_[0]};
	$self->{OUTPUT} = ':stdout' if (!defined $self->{OUTPUT});
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

sub fh
{
	my $self = shift;
	if (@_) {$self->{FH} = $_[0]};
	$self->{FH} = undef if (!defined $self->{FH});
	return $self->{FH};
}

sub data
{
	my $self = shift;
	if (@_) {$self->{DATA} = $_[0]};
	$self->{DATA} = undef if (!defined $self->{DATA});
	return $self->{DATA};
}

# Autoload or overwrite using SUPER or call direct?
# currently call direct and pass in a datahandle to write to
sub _format
{
	my $self = shift;
	if (@_) {$self->{_FORMAT} = $_[0]};
	my $out = $self->format;
	$self->{_FORMAT} = XML::TV::Output::$out->new(Data => $self->data, Format => $self->format);
	return $self->{_FORMAT};
}

# Ok start will open files for writing, or if stdout, do absolutely nothing
# return 1 on success undef on error.
sub start
{
	my $self = shift;
	my $ret = 1;
	if ($self->output eq ':stdout')
	{
		$self->fh = *STDOUT;
	} else {
		open $self->fh ">" $self->filename
			or $ret = undef;
		warn("FATAL: Unable to open " . $self->filename . ": $!") if (!defined $ret);
	}
	return $ret;
}

# ok finish will say we're all done with the format and we want to write it (if stdout just print everything).
# return 1 on success undef on error.  Unopened filehandle will return undef.
sub finish
{
	my $self = shift;
	return undef if (!defined $self->fh);
	print $self->fh $self->data;
	close $self->fh if ($self->output ne ':stdout');
	return 1;
}

1;
