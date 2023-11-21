#!/bin/bash

# Place all content from the specified branch on top of the corresponding
# locations in /etc/httpd, overwriting existing files, else creating new.
# EXAMPLE: sh baseline.sh prod
refresh() {
  local branch="$1"
  [ -z "$branch" ] && echo "Branch not specified!" && return;

  for file in $(git ls-tree -r --name-only $branch) ; do
    echo $file; 
    git show ${branch}:${file} > /etc/httpd/$file
  done
}

refresh $@