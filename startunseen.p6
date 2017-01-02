#!/home/wolf/rakudo-star-2016.01/install/bin/perl6
use v6;

use lib "/home/wolf/repos/startunseen/lib";
use FileSys::Searcher;
use FileSys::Movie;
use Config;

my $config-file-content = q:to/END/;
# config file for startunseen script
download-dir = /mnt/downloads
debug = 1
# all search pathes will be used to look in for movie files.
# the second string is used to find the particular movies in all one
search-path = /home/wolf/vids/bigbangtheory;bang\.theory
search-path = /home/wolf/vids/mythbusters;mythbuster
END

my %config = Config.load($config-file-content, 'startunseen');
my $download-dir = %config<download-dir>.IO;
my $search-dirs = %config<search-path>;

multi MAIN() {
    start();
}

multi MAIN(Str $help where * ~~ /'-h'|'--help'/) {
    help();
}

multi MAIN('rename', Bool \debug = False) {
    if $download-dir !~~ :e {
        warn "$download-dir has not be mounted";
    }
    rename-movies(); 
}

multi MAIN('copy-new', Bool \debug = False) {
    if $download-dir !~~ :e {
        warn "$download-dir has not be mounted";
    }
    copy-new();
}

multi MAIN('latest-vid', Bool \debug = False) {
    for get-search-dirs() -> $search {
        my ($search-dir) = $search.split(';');
        say "Check $search-dir";
        my $searcher = FileSys::Searcher.new(path => $search-dir);
        my $latest-movie = $searcher.getLastMovie();
        say $latest-movie.name;
    }

    #say (@mb.sort({ .series && .episode }))[*-1].name;
}

sub USAGE() {
    help();
}

sub get-search-dirs() {
    my @search-dirs-new;
    if $search-dirs ~~ Array {
        my @root = $search-dirs;
        for @root -> @search-array {
            for @search-array -> $array {
                @search-dirs-new.push: $array;
            }
        }
    }
    else {
        @search-dirs-new.push: $search-dirs;
    }

    @search-dirs-new;
}

sub rename-movies {
    my $searcher = FileSys::Searcher.new(notrecognized => 1);
    my @failedmovies = $searcher.getMovies();
    
    for @failedmovies -> $fm {
        say $fm.name;
        my $nname = prompt("New name: ");
        $fm.renameMovie($nname); 
    }
}

sub copy-new {
    # get the youngest local
    my $latest;
    for get-search-dirs() -> $search {
        my ($search-dir,$search-pattern) = $search.split(';');
        my $searcher = FileSys::Searcher.new(path => $search-dir);
        $latest = $searcher.getLastMovie();
        say "latest in $search-dir is ", $latest.name;
    
        my $remote = FileSys::Searcher.new(path => $download-dir);
        my @remote = $remote.getMovies($search-pattern);

        for @remote -> $movie {
            if $latest.series < $movie.series {
                say "Found newer season: ", $movie.name;
                my $newname = $*SPEC.catfile($search-dir, $movie.name);
                say $newname;
                $movie.io.copy($newname);
            }
            elsif $latest.series == $movie.series and $latest.episode < $movie.episode {
                say "Found new epsiode; ", $movie.name;
                my $newname = $*SPEC.catfile($search-dir, $movie.name);
                say $newname;
                $movie.io.copy($newname);
            }
        }
    }
}

sub start {
    # create ./seen dir if not already exists
    my $cwd = $*CWD.abspath;
    my $seen = $cwd ~ "/seen";

    my $searcher = FileSys::Searcher.new(path => $cwd, recursive => 0);
    my @movies = $searcher.getMovies();

    for @movies -> $movie {
        say $movie.name;
    }
    
    if @movies.elems == 0 {
        copy-new();
        @movies = $searcher.getMovies();
    }

    my @sorted = @movies.sort( { .episode });

    if 0 == @movies.elems {
        say "no vids found in the current directory";
        exit;
    }

    for @sorted -> $io {
        say $io.name;
    }

    say "start: ", @sorted[0].name;
    my $cmd = '/usr/bin/mpv "' ~ @sorted[0].io.abspath ~ '" 2>&1';

    say $cmd;
    my @output = qqx/$cmd/.lines;

    my $percent;
    for @output -> $line {
        $percent = $0 if $line ~~ /^AV\:\s+.*?\((\d+)\%\)\s+/;
    }

    if 96 >= $percent.Str {
        my $mv_ans = prompt("Only " ~ $percent.Str ~ "% played. Should I move the just played file? Y/n ");
        if "n" eq lc $mv_ans {
            return; # do not move file.
        }
    }

    unless $seen.IO ~~ :e {
        $seen.IO.mkdir;
    }
    my $path_to_move = $cwd ~ "/seen/" ~ @sorted[0].name;
    @sorted[0].io.copy($path_to_move);
    @sorted[0].io.unlink;
}

sub help {
    say qq:to/HELP/;
startunseen OPTION

OPTION
    start: starts the oldest video in the same directory
    copy-new: copy new videos
    latest-vid: shows the oldest vids
    rename: shows all movies with not recognized series/episodes

CONFIGURATION
    To set the path variables check out $*HOME/.config/startunseen/config
HELP
}
