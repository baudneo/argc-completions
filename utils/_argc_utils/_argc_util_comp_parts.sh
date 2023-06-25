_argc_util_comp_parts() {
    awk -v SEP="$1" -v ARGC_MATCHER="${2-$ARGC_MATCHER}" -v ARGC_PREFIX="${3}" '
BEGIN {
    split("", VALUES)
    split("", DEDUPS)
    ONLY_LINE = ""
    COUNT = 0
    split(ARGC_MATCHER, matchers, SEP)
    MATCHER = matchers[length(matchers)]
    PREFIX = ""
    for (i = 1; i < length(matchers); i++) 
        PREFIX = PREFIX matchers[i] SEP
    print "__argc_matcher:" MATCHER
    print "__argc_prefix:" ARGC_PREFIX PREFIX
}
{
    if (index($0, ARGC_MATCHER) == 1) {
        value = substr($0, length(PREFIX) + 1)
        if (COUNT == 0) {
            ONLY_LINE = value
            if (substr(ONLY_LINE, length(ONLY_LINE)) == SEP) {
                ONLY_LINE = ONLY_LINE "\0"
            }
        }
        COUNT = COUNT + 1
        idx = index(value, SEP)
        if (idx > 0) {
            value = substr(value, 1, idx) "\0"
        }
        if (!DEDUPS[value]) {
            DEDUPS[value] = 1
            VALUES[length(VALUES) + 1] = value
        }
    }
}

END {
    if (COUNT == 1) {
        print ONLY_LINE
    } else {
        for (i in VALUES) {
            print VALUES[i]
        }
    }
}'
}