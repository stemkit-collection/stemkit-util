#!/bin/sh
# vim: set sw=2:

[ "${#}" -eq 0 ] && {
  echo "USAGE: ${0} <repository> ..." 1>&2
  exit 2
}

while [ ${#} -ne 0 ]; do 
  repository="${1}"
  echo "Repository: ${repository}"
  rm -rf "${repository}"
  rsync -avq "${repository}".svn.sourceforge.net::svn/"${repository}"/\* "${repository}" && {
    head_revision=`svnlook youngest "${repository}"`
    [ "${head_revision:+set}" = set ] && {
      echo "Head revision: ${head_revision}"
      svnadmin dump -q --deltas -r 0:"${head_revision}" "${repository}" | bzip2 -c > "${repository}.0-${head_revision}.svn-dump.bz2"
      rm -rf "${repository}"
    }
  }
  shift
done
