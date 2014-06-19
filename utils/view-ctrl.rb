#!/usr/bin/ruby -np
# Colorize control characters for ruby inspect output
#alias vc
$_.gsub!(/\\x(..)/,"\033[1;34m(\\1)\33[0m")
