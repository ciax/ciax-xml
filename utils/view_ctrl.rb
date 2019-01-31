#!/usr/bin/env ruby -np
# Colorize control characters for ruby inspect output
# alias vc
$LAST_READ_LINE.gsub!(/\\x(..)/, "\033[1;34m(\\1)\33[0m")
