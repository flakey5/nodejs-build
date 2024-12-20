#!/usr/bin/env bash

set -e

site=$1
dstdir=$2
version=$3

__dirname="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. ${__dirname}/settings

if [ "X${site}" == "X" ]; then
  echo "site argument not provided"
  exit 1
fi

if [ "X${dstdir}" == "X" ]; then
  echo "dstdir argument not provided"
  exit 1
fi

if [ "X${version}" == "X" ]; then
  echo "version argument not provided"
  exit 1
fi

if [ -z ${dist_rootdir+x} ]; then
  echo "\$dist_rootdir is not set"
  exit 1
fi

if [ -z ${staging_bucket+x} ]; then
  echo "\$staging_bucket is not set"
  exit 1
fi

if [ -z ${rclone_log+x} ]; then
    echo "\$rclone_log is not set"
    exit 1
fi

if [ -z ${rclone_log_level+x} ]; then
  rclone_log_level=INFO
fi

(cd "${dstdir}/${version}" && shasum -a256 $(ls node* openssl* iojs* win-*/* x64/* 2> /dev/null) > SHASUMS256.txt) || exit 1
if [[ $version =~ ^v[0] ]]; then
  (cd "${dstdir}/${version}" && shasum $(ls node* openssl* x64/* 2> /dev/null) > SHASUMS.txt) || exit 1
fi
echo "${dstdir}/${version}/SHASUMS256.txt"
nodejs-dist-indexer --dist $dstdir --indexjson ${dstdir}/index.json  --indextab ${dstdir}/index.tab
find "${dstdir}/${version}" -type f -exec chmod 644 '{}' \;
find "${dstdir}/${version}" -type d -exec chmod 755 '{}' \;

relativedir=${dstdir/$dist_rootdir/"$site/"}
rclone copyto \
  --log-level=${rclone_log_level} \
  --log-file=${rclone_log} \
  ${dstdir}/index.json \
  $staging_bucket/$relativedir/index.json > /dev/null
rclone copyto \
  --log-level=${rclone_log_level} \
  --log-file=${rclone_log} \
  ${dstdir}/index.tab \
  $staging_bucket/$relativedir/index.tab > /dev/null
rclone copyto \
  --log-level=${rclone_log_level} \
  --log-file=${rclone_log} \
  ${dstdir}/${version}/SHASUMS256.txt \
  $staging_bucket/$relativedir/${version}/SHASUMS256.txt > /dev/null
  