#!/bin/bash
LINK=$(basename $0)
DIR=$(dirname $0)
${DIR}/zlayer.sh ${DIR}/../$LINK ${@:1} > ${LINK}_snif.out 2>&1

