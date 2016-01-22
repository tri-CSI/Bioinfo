#!/usr/bin/awk -f
BEGIN {
    FS = "|";
    eas_pos = 0;
    sas_pos = 0;
}

/^#/ {
    # set the field number of EAS_MAF and SAS_MAF
    if ( $0 ~ /EAS_MAF/ ) {
        for ( i=1; i<=NF; i++ ) {
            if ( $i == "EAS_MAF" ) eas_pos = i;
            else if ( $i == "SAS_MAF" ) sas_pos = i;
        }
        print $0"\tEAS_MAF\tSAS_MAF";
    }
    else { print; }
    
}

!/^#/ {
    # extract values from EAS_MAF and SAS_MAF field
    split( $eas_pos, eas, "[:&]" );
    split( $sas_pos, sas, "[:&]" );
    print $0"\t"eas[2]"\t"sas[2];
}
