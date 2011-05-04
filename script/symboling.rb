#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libsym"
require "libmods2h"
include S2h

abort "Usage: symboling [file]" if STDIN.tty? && ARGV.size < 1

begin
  stat=s2h(JSON.load(gets(nil)))
  if frm=stat['header']['frame']
    doc=XmlDoc.new('fdb',frm)
  elsif cls=stat['header']['class']
    doc=XmlDoc.new('cdb',cls)
  else
    raise "NO ID in Status"
  end
  sym=Sym.new(doc)
  res=sym.convert(stat)
  puts JSON.dump(res)
rescue
  abort $!.to_s
end
