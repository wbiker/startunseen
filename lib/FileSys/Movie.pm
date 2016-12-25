use v6;

use FileSys::Grammar;

class FileSys::Movie {
    has $.io;
    has $.name;
    has $.series;
    has $.episode;

    method setMovie(IO::Path:D $io) {
        $!io = $io;
        $!name = $io.basename;
        my $match = serie-episode.subparse($io.basename);
        if $match {
            $!series = +$match<series>;
            $!episode = +$match<episode>;
        } else {
            $match = serieepisode.subparse($io.basename);

            if $match {
                $!series = +$match<serie>;
                $!episode = +$match<episode>;
            } else {
                $match = serieepisodeplain.subparse($io.basename);
                if $match {
                    $!series = +$match<serie>;
                    $!episode = +$match<episode>;
                } else {
                    warn "Could not find serie and episode in " ~  $io.basename;
                }
            }
        }   
    }

    method renameMovie($newname) {
        return unless $newname;

        my $ext = $.io.extension;
        my $namewext = $newname;
        if not $newname ~~ /$ext/ {
            $namewext ~= "." ~ $.io.extension;
        }

        my $newpath = $*SPEC.catfile($.io.dirname, $namewext);
        say $newpath;
    }
}
