#
# Print URLs to a window named "urlslurp" for
# irssi 0.7.99 by DigitalCold

use Irssi;
use POSIX;
use vars qw($VERSION %IRSSI); 

require URI::Find::Schemeless;

$VERSION = "0.1";
%IRSSI = (
    authors     => "DigitalCold",
    contact     => "digitalcold0\@gmail.com", 
    name        => "urlslurp",
    description => "Print found URLs to window named \"urlslurp\".",
    license     => "Public Domain",
    url         => "https://hernan.de/z",
    changed     => "Thu Jun  2 15:17:00 EDT 2016"
);

sub sig_public {
    my ($server, $msg, $nick, $addr, $target) = @_;

    search_urls($target, $nick, $msg);
}

sub sig_private {
    my ($server, $msg, $nick, $addr) = @_;

    my $choice = Irssi::settings_get_bool('urlslurp_private');

    search_urls($server->{nick}, $nick, $msg) if ($choice);
}

sub sig_ownpublic {
    my ($server, $msg, $target) = @_;

    search_urls($target, $server->{nick}, $msg);
}

sub sig_ownprivate {
    my ($server, $msg, $target, $orig_target) = @_;

    my $choice = Irssi::settings_get_bool('urlslurp_private');

    search_urls($target, $server->{nick}, $msg) if ($choice)
}

sub format_log {
    my ($where, $from, $msg) = @_;

    my $time = strftime(
        Irssi::settings_get_str('timestamp_format'),
        localtime
    );

    # Format: 12:01 #channel: <nick> message https://www.google.com/
    return $time." ".$where.": <".$from."> ".$msg;
}

sub search_urls {
    my ($where, $from, $msg) = @_;

    $window = Irssi::window_find_name('urlslurp');

    # make sure we actually have a window
    return if not $window;

    my @uris;
    my $useContext = Irssi::settings_get_bool('urlslurp_context');

    # figure out if we should process this place
    my $blacklist = Irssi::settings_get_str('urlslurp_ignore_list');
    return if (index($blacklist, $where) != -1);

    my $finder = URI::Find::Schemeless->new(sub {
        my $new_url = $_[0];

        push @uris, $new_url;

        # prevent color escape sequences from URLs
        $new_url =~ s/%/%%/g;

        # add some URL coloring
        return "%y".$new_url."%n";
      });

    $found = $finder->find(\$msg);

    return if $found <= 0;

    my $text = format_log($where, $from, $useContext ? $msg : join(", ", @uris));
    $window->print($text, MSGLEVEL_NEVER);
}

# check for magic window
$window = Irssi::window_find_name('urlslurp');
Irssi::print("Create a window named 'urlslurp'") if (!$window);

# Settings

# Ignore URLs from these places (channels)
Irssi::settings_add_str('urlslurp','urlslurp_ignore_list',"");

# Capture URLs in private messages
Irssi::settings_add_bool('urlslurp','urlslurp_private',0);

# Show URLs with context
Irssi::settings_add_bool('urlslurp','urlslurp_context',1);

# signals
Irssi::signal_add_last("message public", "sig_public");
Irssi::signal_add_last("message private", "sig_private");
Irssi::signal_add_last("message own_private", "sig_private");
Irssi::signal_add_last("message own_public", "sig_private");
