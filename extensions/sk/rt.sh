#!/bin/ksh

[ "${1}" = 'test' ] && {
  return 0
}
irb -I ${JAM_SRCDIR}/.. -I .. -r sk/rt/scope.rb
