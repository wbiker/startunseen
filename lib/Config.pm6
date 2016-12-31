use v6;

unit class Config;

method load($config-file-default-content) {
    my $program = $*PROGRAM.basename;
    my $config-dir = $*SPEC.catdir($*HOME, '.config');
    my $config-program-dir = $*SPEC.catdir($config-dir, $*PROGRAM.basename);
    my $config-program-file = $*SPEC.catfile($config-program-dir, 'config').IO;

    $config-program-dir.mkdir unless $config-program-dir.IO.e;

    if not $config-program-file.e {
        # does not exist.
        $config-program-file.spurt($config-file-default-content);
        my $answer = prompt "Create new config file '$config-program-file'. Do you want to change this? (y|N) ";
        if $answer ~~ /:i 'y'/ {
            shell "\$EDITOR $config-program-file";
        }
        exit;
    }

    my %config;
    for $config-program-file.lines -> $line {
        next if $line ~~ /^^ '#'/;

        if $line ~~ /$<key>=<-[=]>+ \s+ '=' \s+ $<value>=.*/ {
            %config{$<key>} = ~$<value>;
        }
        else {
            die "Config $config-program-file file error: $line not recognized";
        }
    }

    %config;
}
