#!/usr/bin/ruby
require "json"
require "libfrmrsp"
require "libfrmdb"
require "libcache"

args=ARGV.partition{|s| /^-/ === s}
opt=args.shift.join('')
dev=args.shift.first
ARGV.clear

begin
  fdb=Cache.new("fdb_#{dev}"){FrmDb.new(dev)}
  field={}
  r=FrmRsp.new(fdb,field)
  str=gets(nil) || exit
  ary=str.split("\t")
  time=Time.at(ary.shift.to_f)
  stm=ary.shift.split(':')
  abort ("Logline:Not response") unless /rcv/ === stm.shift
  r.setrsp(stm){[time,eval(ary.shift)]}
  puts JSON.dump(field)
rescue RuntimeError
  if opt.include?('q')
    exit 1
  else
    abort "Usage: frmstat [frame] < logline\n#{$!}"
  end
end

