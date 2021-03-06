#!/usr/bin/env bash
#
# Vendor-specific check script. Assumes that pyang is on path and that
# all standard modules are on its internal module path.
#
# Deviation modules are NOT checked as they require specific imports
# typically not available locally.
#
# This script will only be run for the last three releases. When a new
# release is added, the current first release (left to right) should
# be removed.
#
# 2017-09-21 einarnn:
#
# 16.4.1 currently excluded because this release does not include all
# "RFC" models required and pyang cannot be configured to pick correct
# ietf-routing draft without versioned imports.
#
platform_dir="vendor/cisco/xe"
to_check="1651 1651/MIBS 1661 1661/MIBS"
inc_path="."
debug=0

checkDir () {
    if [ "$debug" -eq "1" ]; then
	echo Checking yang files in $platform_dir/$1
    fi
    cwd=`pwd`
    cd $1
    exit_status=""
    pyang_flags=""
    if [ `basename $PWD` == "MIBS" ]; then
        pyang_flags="-p .."
    fi

    pyang_flags="--lax-quote-checks $pyang_flags"
    for f in *.yang; do
        errors=`YANG_INSTALL="." pyang $pyang_flags $f 2>&1 | grep "error:"`
    	if [ ! -z "$errors" ]; then
    	    echo Errors in $f
            echo $errors
    	    exit_status="failed!"
        fi
    done
    cd $cwd
    
    if [ ! -z "$exit_status" ]; then
	   exit 1
    fi
}

if [ "$debug" -eq "1" ]; then
    printf "\nChecking modules with pyang command:\n"
    printf "\n    pyang $pyang_flags MODULE\n\n"
fi

if [ -e "$platform_dir" ]; then
    cd $platform_dir
fi

declare -a pids
for d in $to_check; do
    (checkDir $d) &
    pids+=("$!")
done

for p in $pids; do
    wait $p || exit 1
done
