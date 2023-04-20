#!/bin/bash

source /etc/httpd/conf.d/s3proxy/credentials.sh

source /etc/httpd/conf.d/s3proxy/signer.sh 'wait'

PROXY_PASS_HOST="${OLAP}-${AWS_ACCOUNT_NBR}.s3-object-lambda.${REGION}.amazonaws.com"

while read parms ; do

  if [ "$parms" == 'utcdate' ] ; then
    date -u +%Y%m%dT%H%M%SZ
    continue
  fi

  if [ "$parms" == 'host' ] ; then
    echo "$PROXY_PASS_HOST"
    continue
  fi

  timestamp="$(echo $parms | cut -d'&' -f1)"
  objectkey="$(echo $parms | cut -d'&' -f2)"
  
  retval="$(run "task=auth" "debug=true" "object_key=$objectkey" "time_stamp=$timestamp" "host=$PROXY_PASS_HOST" "aws_access_key_id=$AWS_ACCESS_KEY_ID" "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" "aws_session_token=$AWS_SESSION_TOKEN")"
  retcode=$?
  if [ $retcode -eq 0 ] ; then
    if [ "$retval" == 'NULL' ] || [ -z "$retval" ] ; then
      log "retcode=0, NULL"
      echo 'NULL'
    else
      log "retval = \"$retval\""
      echo "$retval"
    fi
  else
    log "retcode=$retcode, NULL"
    echo 'NULL'
  fi
done
