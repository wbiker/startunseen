#!/home/wolf/rakudo-star-2016.01/install/bin/perl6
use v6;

use lib "/home/wolf/repos/startunseen/lib";
use FileSys::Searcher;
use FileSys::Movie;

my $download-dir = "/mnt/download".IO;
my $debug = True;

my %config = (
    download-dir => '/mnt/download'.IO,
    debug => True,
);

multi MAIN() {
    start(); 
}

multi MAIN('help') {
    help();
}

multi MAIN('rename', Bool \debug = False) {
    if %config<download-dir> !~~ :e {
        warn "/mnt/nas/download has not be mounted";
    }
    rename-movies(); 
}

multi MAIN('copy-new', Bool \debug = False) {
    if $download-dir !~~ :e {
        die "$download-dir not mounted";
    }
    copy-new();
}

multi MAIN('latest-vid', Bool \debug = False) {
    my $searcher = FileSys::Searcher.new(path => "/home/wolf/vids/bigbangtheory");
    my $latest-movie = $searcher.getLastMovie();
    say $latest-movie.name;

    my $seamb = FileSys::Searcher.new(path => "/home/wolf/vids/mythbusters");
    my @mb = $seamb.getMovies();

    say (@mb.sort({ .series && .episode }))[*-1].name;
}

sub USAGE() {
    help();
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
    my $bb_path = "/home/wolf/vids/bigbangtheory";
    my $mb_path = "/home/wolf/vids/mythbusters";
   # get the youngest local
   my $searcher = FileSys::Searcher.new(path => $bb_path);
    my $bb-latest = $searcher.getLastMovie();
    say "latest bbt is ", $bb-latest.name;

    my $searcher_mb = FileSys::Searcher.new(path => $mb_path);
    my $mb-latest = $searcher_mb.getLastMovie();
    say "latest mb is ", $mb-latest.name;
    # fetch all files

    my $remote-bb = FileSys::Searcher.new;
    my @remote-bb = $remote-bb.getMovies("bang\.theory");

    for @remote-bb -> $movie {
        if $bb-latest.series < $movie.series {
            say "Found newer season: ", $movie.name;
            my $newbbname = $*SPEC.catfile($bb_path, $movie.name);
            say $newbbname;
            $movie.io.copy($newbbname);
        }
        elsif $bb-latest.series == $movie.series and $bb-latest.episode < $movie.episode {
            say "Found new bb epsiode; ", $movie.name;
            my $newbbname = $*SPEC.catfile($bb_path, $movie.name);
            say $newbbname;
            $movie.io.copy($newbbname);
        }
    }

    my $remote-mb = FileSys::Searcher.new;
    my @remote-mb = $remote-mb.getMovies("mythbusters");

    for @remote-mb -> $mv {
        if $mb-latest.series < $mv.series {
            say "Found newer season: ", $mv.name;
            my $newbmname = $*SPEC.catfile($mb_path, $mv.name);
            say $newbmname;
            $mv.io.copy($newbmname);
        }
        elsif $mb-latest.series == $mv.series and $mb-latest.episode < $mv.episode {
            say "Found new mb episode ", $mv.name;
            my $newbmname = $*SPEC.catfile($mb_path, $mv.name);
            say $newbmname;
            $mv.io.copy($newbmname);
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
HELP
}
