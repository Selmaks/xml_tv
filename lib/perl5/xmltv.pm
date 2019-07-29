package xmltv;
use IO::Socket::SSL;
my $FURL_OK = eval 'use Furl; 1';
if (!$FURL_OK)
{
	warn("Furl not found, falling back to LWP for fetching URLs (this will be slow)...\n");
	use LWP::UserAgent;
}
#require xmltv::freeview;
require xmltv::abc;
require xmltv::sbs;

{
    sub new {
        my $source  = shift;
        my $self       = {@_};
        $self->{source}   = undef unless $self->{source};
        $self->{region}    = undef unless $self->{region};
        $self->{epgdays}    = 7 unless $self->{epgdays};
        $self->{includechannels}    = undef unless $self->{includechannels};
        $self->{ignorechannels}    = undef unless $self->{ignorechannels};
        $self->{duplicatechannels}    = undef unless $self->{duplicatechannels};
        $self->{verbose}    = 0 unless $self->{verbose};
        my $VERBOSE = $self->{verbose};
        my $getepg = $self->{source}."_getepg";
        my $getchannels = $self->{source}."_getchannels";
        $self->{functions} = {
            'getepg'     => \&$getepg,
            'getchannels'    => \&$getchannels,
        };
        if ($FURL_OK)
        {
	        warn("Using Furl for fetching http:// and https:// requests.\n") if ($VERBOSE);
	        $self->{ua} = Furl->new(
				agent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0',
				timeout => 30,
				headers => [ 'Accept-Encoding' => 'application/json' ],
				ssl_opts => {SSL_verify_mode => 0}
			);
        }
        else
        {
	        warn("Using LWP::UserAgent for fetching http:// and https:// requests.\n") if ($VERBOSE);
	        $self->{ua} = LWP::UserAgent->new;
	        $self->{ua}->agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:67.0) Gecko/20100101 Firefox/67.0");
	        $self->{ua}->default_header( 'Accept-Encoding' => 'application/json');
	        $self->{ua}->default_header( 'Accept-Charset' => 'utf-8');
        }
        bless($self,$source);
        return $self;
    }

    sub getepg {
        my $this = shift;
        my $key = $this->{functions}->{getepg};
        print "Hello $this->{source}\n";
        return &$key($this->{ua},$this->{epgdays},$this->{verbose});

    }
    sub getchannels {
        my $this = shift;
        my $key = $this->{functions}->{getchannels};
        return &$key($this->{verbose});

    }

    1;
}