#!/usr/bin/ruby
require "json"
require "libclsdb"
require "libsym"
require "libmods2q"
include S2q

abort "Usage: symboling [file]" if STDIN.tty? && ARGV.size < 1

begin
  stat=s2q(JSON.load(gets(nil)))
  if frm=stat['header']['frame']
    require "libfrmdb"
    db=FrmDb.new(frm)
  elsif cls=stat['header']['class']
    db=ClsDb.new(cls)
  else
    raise "NO ID in Status"
  end
  sym=Sym.new(db)
  res=sym.convert(stat)
  puts JSON.dump(res)
rescue
  abort $!.to_s
end
