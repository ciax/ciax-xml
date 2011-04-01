#!/usr/bin/ruby
require "json"
require "libxmldoc"
require "libsym"
abort "Usage: symboling [file]" if STDIN.tty? && ARGV.size < 1

begin
  stat=JSON.load(gets(nil))
  if frm=stat['frame']
    doc=XmlDoc.new('fdb',frm)
  elsif cls=stat['class']
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
