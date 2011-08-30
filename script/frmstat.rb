#!/usr/bin/ruby
require "libstat"
require "libfrmrsp"
require "libfrmdb"

args=ARGV.partition{|s| /^-/ === s}
opt=args.shift.join('')
dev=args.shift.first
ARGV.clear

begin
  fdb=FrmDb.new(dev)
  field=Field.new
  r=FrmRsp.new(fdb,field)
  str=gets(nil) || exit
  ary=str.split("\t")
  time=Time.at(ary.shift.to_f)
  stm=ary.shift.split(':')
  abort ("Logline:Not response") unless /rcv/ === stm.shift
  r.setrsp(stm){[time,eval(ary.shift)]}
  puts field.to_j
rescue RuntimeError
  if opt.include?('q')
    exit 1
  else
    abort "Usage: frmstat [frame] < logline\n#{$!}"
  end
end

