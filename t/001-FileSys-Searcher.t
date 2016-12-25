use v6;
use Test;

use lib '.';

use FileSys::Searcher;

# setup test dir and files
my $test-dir = './files';
mkdir $test-dir;

my $searcher = FileSys::Searcher.new(path => $test-dir);

subtest {
    plan 1;
    my @movies = $searcher.getMovies;
    is @movies.elems, 0, "No movie files there.";
}, 'Only movies with mkv,mp4 or avi are found';

# test if a non movie file is found.

subtest {
    my @test-files = (
        [$*SPEC.catfile($test-dir, 'test.1101.mkv'), 'mkv extension file found'],
        [$*SPEC.catfile($test-dir, 'test.0110.mp4'), 'mp4 extension file found'],
        [$*SPEC.catfile($test-dir, 'test.1001.avi'), 'avi extension file found'],
    );

    plan @test-files.elems;
    for @test-files.kv -> $i, $test-file {
        # create some movie dummy files.
        $test-file[0].IO.spurt: 'dummy';
        my @movies = $searcher.getMovies;
        is @movies.elems, 1, $test-file[1];
        $test-file[0].IO.unlink;
    }
}, 'test file extension recognition';

# delete all files and create dir again
rm-all($test-dir.IO);
mkdir $test-dir;

subtest {
    my @test-files = (
        [$*SPEC.catfile($test-dir, 'test. 1101.mkv'),   ' 1101 found'],
        [$*SPEC.catfile($test-dir, 'test.1101.mkv'),    '.1101 found'],
        [$*SPEC.catfile($test-dir, 'test-1101.mkv'),    '-1101 found'],
        [$*SPEC.catfile($test-dir, 'test.S11E01.mkv'),  '.S11E01 found'],
        [$*SPEC.catfile($test-dir, 'test.s11e01.mkv'),  '.s11e01 found'],
        [$*SPEC.catfile($test-dir, 'test-s11e01.mkv'),  '-s11e01 found'],
        [$*SPEC.catfile($test-dir, 'test-S11E01.mkv'),  '-S11E01 found'],
        [$*SPEC.catfile($test-dir, 'test-S11E01.mkv'),  '-S11E01 found'],
        [$*SPEC.catfile($test-dir, 'test S11E01.mkv'),  ' S11E01 found'],
        [$*SPEC.catfile($test-dir, 'test s11E01.mkv'),  ' s11E01 found'],
        [$*SPEC.catfile($test-dir, 'test.s11e01.mkv'),  '.11e01 found'],
        [$*SPEC.catfile($test-dir, 'test.1101.mkv'),    '.1101 found'],
        [$*SPEC.catfile($test-dir, 'test.101.mkv'),     '.101 found'],
        [$*SPEC.catfile($test-dir, 'test 101.mkv'),     ' 101 found'],
        [$*SPEC.catfile($test-dir, 'test-101.mkv'),     '-101 found'],
    );
    plan @test-files.elems;
    for @test-files.kv -> $i, $test-file {
        # create some movie dummy files.
        $test-file[0].IO.spurt: 'dummy';
        my @movies = $searcher.getMovies;
        is @movies.elems, 1, $test-file[1];
        $test-file[0].IO.unlink;
    }
}, 'test serie/episode in file names';

rm-all($test-dir.IO);
done-testing;

multi sub rm-all(IO::Path:D $path where :d) {
    rm-all($_) for $path.dir;
    rmdir($path);
}

multi sub rm-all(IO::Path:D $path) {
    $path.unlink;
}
