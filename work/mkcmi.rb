#!/usr/bin/ruby
# Generate Current Mask Index to status_cmi.json
require 'json'
# Condition Matrix
# mmc:con | mfp:ao | mfp:rh | mma:abs | cmi
#   OFF   | CLOSE  | OPEN   | FOCUS   | nomask
#   OFF   | OPEN   | OPEN   | FOCUS   | nomask
#   OFF   | CLOSE  | CLOSE  | FOCUS   | #
#   OFF   | OPEN   | CLOSE  | FOCUS   | #
#   OFF   | -      | -      | INIT    | #
#   OFF   | -      | -      | >FOCUS  | #
#   ON    | -      | -      | -       | nomask

# Status file name
def mkfile(site)
  jdir = "#{ENV['HOME']}/.var/json"
  "#{jdir}/status_#{site}.json"
end

# Mask is Focal plane?
def on_mask?(stat)
  return if stat[:con] == 'ON'
  return true if stat[:abs] == 'INIT'
  return unless stat[:abs] == 'FOCUS'
  stat[:rao] == 'CLOSE' && stat[:rbo] == 'CLOSE'
end
pfx = "#{ENV['PROJ']}" == 'dummy' ? 't' : 'm'
src = {}
%w(fp ma mc).each do |s|
  file = mkfile(pfx + s)
  src[s.to_sym] = JSON.parse(IO.read(file), symbolize_names: true)
end
stat = {}
idx =  { con: :mc, ao: :fp, rao: :fp, rbo: :fp, abs: :ma, rsl: :mc }
idx.each { |k, v| stat[k] = src[v][:msg][k] } 
cmi = on_mask?(stat) ? stat[:rsl] : 'nomask'
hash = { time: src[:mc][:time], id: 'cmi', msg: { cmi: cmi } }
json = JSON.pretty_generate(hash)
IO.write(mkfile('cmi'), json)
puts cmi
