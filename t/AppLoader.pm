package AppLoader;
use v5.14.1;
use Plack::Request;
use Plack::Response;
use Plack::Util;
use URI;
use HTTP::Tiny;

sub new {
    my (undef, $name, $class) = @_;

    my $url = $ENV{TEST_URL} // '';

    if ($url eq 'local') {
        return app_from_url("http://localhost:5000");
    } elsif ($url eq 'deployed') {
        my $config = "/etc/default/$name";
        my %conf = do { 
            local(@ARGV) = $config; 
            map { /^\s*([^=\s#]+)\s*=\s*([^#\n]*)/ ? ($1 => $2) : () } <>;
        };
        return app_from_url("http://localhost:".$conf{PORT});
    } elsif ($url =~ qr{^https?://}) {
        return app_from_url($url);
    } elsif (-f $url) {
        return Plack::Util::load_psgi($url);
    } elsif ($class) {
        say "# testing $class";
        my $class = Plack::Util::load_class($class);
        return $class->new->to_app;
    }

    return;
}

sub app_from_url {
    my $url = URI->new(shift);
    my ($scheme, $host, $port) = ($url->scheme, $url->host, $url->port);
    return sub {
        my $req = Plack::Request->new(shift);
        my @headers;
        $req->headers->scan(sub { push @headers, @_ });
        my $options = { headers => {} };
        $options->{headers} = Hash::MultiValue->new(@headers)->mixed if @headers;
        delete $options->{headers}->{Host}; # not allowed by HTTP::Tiny
        $options->{content} = $req->content if length($req->content);
        my $uri = $req->uri;
        $uri->scheme($scheme);
        $uri->host($host);
        $uri->port($port);
        printf "# %s %s\n", $req->method, $uri;
        my $res = HTTP::Tiny->new->request( $req->method, $uri, $options );
        say "# ".$res->{content} if $res->{status} == 599;
        return Plack::Response->new( $res->{status}, $res->{headers}, $res->{content} )->finalize;
    };
}

1;
