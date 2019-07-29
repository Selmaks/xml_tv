package xmltv;
use IO::Socket::SSL;
use XML::Writer;
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
        $self->{pretty}    = undef unless $self->{pretty};
        $self->{output}    = undef unless $self->{output};
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
        @{$this->{epg}} = &$key($this->{ua},$this->{epgdays},$this->{verbose});
        return @{$this->{epg}};
    }
    sub getchannels {
        my $this = shift;
        my $key = $this->{functions}->{getchannels};
        @{$this->{channels}} = &$key($this->{verbose});
        return @{$this->{channels}};
    }

    sub buildxml {
        my $this = shift;
        warn("Starting to build the XML...\n") if ($this->{verbose});
        $this->{xml} = XML::Writer->new( OUTPUT => 'self', DATA_MODE => ($this->{pretty} ? 1 : 0), DATA_INDENT => ($this->{pretty} ? 8 : 0) );
        $this->{xml}->xmlDecl("ISO-8859-1");
        $this->{xml}->doctype("tv", undef, "xmltv.dtd");
        $this->{xml}->startTag('tv', 'generator-info-url' => "http://www.xmltv.org/");

        warn("Building the channel list...\n") if ($this->{verbose});
	    foreach my $channel (@{$this->{channels}})
	    {
		    $this->{xml}->startTag('channel', 'id' => $channel->{id});
		    $this->{xml}->dataElement('display-name', $channel->{name});
		    $this->{xml}->dataElement('lcn', $channel->{lcn});
		    $this->{xml}->emptyTag('icon', 'src' => $channel->{icon}) if (defined($channel->{icon}));
		    $this->{xml}->endTag('channel');
	    }
        #printchannels(\$XML);
        warn("Building the EPG list...\n") if ($this->{verbose});
	    foreach my $items (@{$this->{epg}})
	    {
		my $movie = 0;
		my $originalairdate = "";

		$this->{xml}->startTag('programme', 'start' => "$items->{start}", 'stop' => "$items->{stop}", 'channel' => "$items->{id}");
		${$this->{xml}}->dataElement('title', sanitizeText($items->{title}));
		${$this->{xml}}->dataElement('sub-title', sanitizeText($items->{subtitle})) if (defined($items->{subtitle}));
		${$this->{xml}}->dataElement('desc', sanitizeText($items->{desc})) if (defined($items->{desc}));
		foreach my $category (@{$items->{category}}) {
			${$this->{xml}}->dataElement('category', sanitizeText($category));
		}
		${$this->{xml}}->emptyTag('icon', 'src' => $items->{url}) if (defined($items->{url}));
		if (defined($items->{season}) && defined($items->{episode}))
		{
			my $episodeseries = sprintf("S%0.2dE%0.2d",$items->{season}, $items->{episode});
			${$XMLRef}->dataElement('episode-num', $episodeseries, 'system' => 'SxxExx');
			my $series = $items->{season} - 1;
			my $episode = $items->{episode} - 1;
			$series = 0 if ($series < 0);
			$episode = 0 if ($episode < 0);
			$episodeseries = "$series.$episode.";
			${$XMLRef}->dataElement('episode-num', $episodeseries, 'system' => 'xmltv_ns') ;
		}
		${$XMLRef}->dataElement('episode-num', $items->{originalairdate}, 'system' => 'original-air-date') if (defined($items->{originalairdate}));
		${$XMLRef}->emptyTag('previously-shown', 'start' => $items->{previouslyshown}) if (defined($items->{previouslyshown}));
		if (defined($items->{rating}))
		{
			${$XMLRef}->startTag('rating');
			${$XMLRef}->dataElement('value', $items->{rating});
			${$XMLRef}->endTag('rating');
		}
		${$XMLRef}->emptyTag('premiere', "") if (defined($items->{premiere}));
		${$XMLRef}->endTag('programme');
	    }
        warn("Finishing the XML...\n") if ($this->{verbose});
        $this->{xml}->endTag('tv');
	    return;
    }

    sub writexml
    {
        my $this = shift;
        if (!defined $this->{output})
        {
        	warn("Finished! xmltv guide follows...\n\n") if ($this->{verbose});
	        print $this->{xml};
	        print "\n" if ($this->{pretty}); # XML won't add a trailing newline
        } else {
	        warn("Writing xmltv guide to ".$this->{output}." ...\n") if ($this->{verbose});
	        open FILE, ">$this->{output}" or die("Unable to open $this->{output} file for writing: $!\n");
	        print FILE $this->{xml};
	        close FILE;
	        warn("Done!\n") if ($this->{verbose});
        }
    }




    1;
}