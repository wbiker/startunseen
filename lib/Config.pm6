use v6;

unit class Config;

method load($config-file-default-content, $program-name) {
    my $config-dir = $*SPEC.catdir($*HOME, '.config');
    my $config-program-dir = $*SPEC.catdir($config-dir, $program-name);
    my $config-program-file = $*SPEC.catfile($config-program-dir, 'config').IO;

    $config-program-dir.IO.mkdir unless $config-program-dir.IO.e;

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
            my $key = ~$<key>;
            my $value = ~$<value>;
            if %config{$key}:exists {
                my $tmp = %config{$key};
                if $tmp ~~ Array {
                    $tmp.push: $value;
                    %config{$key} = $tmp;
                }
                else {
                    my @new = ($tmp, $value);
                    %config{$key} = @new;
                }
            }
            else {
                %config{$key} = $value;
            }
        }
        else {
            die "Config $config-program-file file error: $line not recognized";
        }
    }

    %config;
}
