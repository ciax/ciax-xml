#!/usr/bin/ruby
# Extract information of Current Mask Index from status_mmc.json to status_mmi.json
require 'json'
abort 'Usage: mmc2cmi [status(json) file]' if STDIN.tty? && ARGV.size < 1
stat = JSON.parse(gets(nil), symbolize_names: true)
msg = stat[:msg]
cmi = msg[:con] == 'OFF' ? msg[:rsl] : 'nomask'
hash = { time: stat[:time], id: 'cmi' , msg: { cmi: cmi }}
jj(hash)
