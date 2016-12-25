use v6;
use FileSys::Movie;

class FileSys::Searcher {
    has @.movies;
    has $.name;
    has $.series;
    has $.path = '/mnt/downloads';
    has $.extension = /\.mp4|\.mkv|\.avi/;
    has $.recursive = 1;
    has $.notrecognized = 0;
    
    method getMovies($name = /.*/) {
        my @movies = self.getFiles($.path.IO, $name);

        @movies;
    }

    method getLastMovie($name = /.*/) {
        my @movies = self.getMovies($name);

        my $latest-movie = FileSys::Movie.new(series => 0, episode => 0);
        for @movies -> $movie {
            if $movie.series > $latest-movie.series {
                $latest-movie = $movie;
                next;
            }
            elsif $movie.series == $latest-movie.series && $movie.episode > $latest-movie.episode {
                $latest-movie = $movie;
                next;
            }
        }

        $latest-movie;
    }

    method getFiles($io, $name) {
        my @files;

        for $io.dir -> $item {
            if $item.d and $.recursive {
                @files.append(self.getFiles($item, $name));
            } else {
                if $item.basename ~~ $.extension {
                    if $item.basename ~~ /:i $name/ {
                        my $m = FileSys::Movie.new();
                        $m.setMovie($item);
                        if $m.series {
                            @files.push($m) if not $.notrecognized;
                        }
                        else {
                            @files.push($m) if $.notrecognized;
                        }
                    }
                }
            }
        }

        @files;
    }
}
