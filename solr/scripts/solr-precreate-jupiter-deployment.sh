#!/bin/bash
#
# This is for docker! Customized script for our jupiter project.
# As jupiter needs both a development and test core.
#
# This script was mostly stolen from the official solr-precreate script:
# https://github.com/docker-solr/docker-solr/blob/master/scripts/solr-precreate
set -e

echo "Executing $0 $@"

if [[ "$VERBOSE" = "yes" ]]; then
    set -x
fi

if [[ -z $SOLR_HOME ]]; then
    coresdir="/opt/solr/server/solr/mycores"
    mkdir -p $coresdir
else
    coresdir=$SOLR_HOME
fi

coredir_staging="$coresdir/staging"
if [[ ! -d $coredir_staging ]]; then
    cp -r /config/ $coredir_staging
    touch "$coredir_staging/core.properties"
    echo "created staging solr core"
else
    echo "core staging already exists"
fi
