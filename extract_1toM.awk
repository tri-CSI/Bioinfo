#!/usr/bin/awk -f
# Extract only main chromosomes (1 to M) from fasta files

BEGIN {
    keep = 0;    
}

/^>/ {
    if ( $0 ~ /^>chr[0-9XYM]+$/ ) { keep = 1; print; }
    else { keep = 0; }
}

!/^>/{
    if (keep) { print; }
}
