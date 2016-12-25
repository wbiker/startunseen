use v6;

grammar serie-episode {
    token TOP { .*? <[ \s | \. ¦ \-]> <[Ss]><series> <[Ee]><episode> \.? .*? }
    token series { \d ** 2 }
    token episode { \d ** 2 }
}

grammar serieepisode {
    token TOP { .*? <seberator> <serie><episode> <seberator> .*? }
    token seberator { || ' ' || \. || \- }
    token serie { \d ** 1..2 }
    token episode { \d ** 2 }
}

grammar serieepisodeplain {
    token TOP { .*? <seberator> <serie><episode> <seberator> .*? }
    token seberator { || ' ' || \. || \- }
    token serie { \d ** 1 }
    token episode { \d ** 2 }
}
