#!/usr/bin/ruby
require "libfilter"
require "libxmldoc"
require "libfrm"
require "readline"

warn "Usage: frmshell [dev] [id] [iocmd] (outcmd)" if ARGV.size < 3

dev=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
out=Filter.new(ARGV.shift)
begin
  doc=XmlDoc.new('fdb',dev)
  fdb=Frm.new(doc,id,iocmd)
rescue SelectID
  abort $!.to_s
end
loop{
  stm=Readline.readline("#{dev}>",true).chomp.split(" ")
  case stm.first
  when /^q/
    fdb.quit
    break
  else
    begin
      fdb.transaction(stm)
    rescue SelectID
      puts $!.to_s
      puts "== Shell Command =="
      puts " q         : Quit"
    rescue RuntimeError
      puts $!.to_s
    end
  end
  puts out.filter(JSON.dump(fdb.field))
}
