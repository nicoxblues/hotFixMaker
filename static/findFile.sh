#!/usr/bin/env bash
date1='$1'
pathCode='$2'


SEARCH=" ! -path '*/.git*'  ! -path '*/.idea*' ! -path '*/.svn*' ! -path '*eclipse*' ! -name '*.java' ! -path '*/target*'  ! -name '*.iml'  ! -name 'pom.xml' ! -name '*.class' "

eval  find $pathCode -type f  $SEARCH -ctime -$date1
