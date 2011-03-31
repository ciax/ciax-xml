#!/usr/bin/ruby
require "json"
require "libcls"
require "libfrm"
require "libxmldoc"
require "readline"
require "libcxcsv"

warn "Usage: csvshell [cls] [id] [iocmd]" if ARGV.size < 3

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
cx=CxCsv.new(id)
begin
  cdoc=XmlDoc.new('cdb',cls)
  fdoc=XmlDoc.new('fdb',cdoc['frame'])
rescue SelectID
  abort $!.to_s
end
fdb=Frm.new(fdoc,id,iocmd)
cdb=Cls.new(cdoc,id,fdb)
loop {
  begin
    line=Readline.readline(cdb.prompt,true) || cdb.interrupt
    cdb.err?
    case line
    when /^q/
      break
    when ''
    else
      line.split(';').each{|cmd|
        stm=cmd.split(' ')
        cdb.dispatch(stm)
      }
    end
    puts cx.mkres(cdb.stat)
  rescue SelectID
    puts $!.to_s
    puts "== Shell Command =="
    puts " q         : Quit"
    puts " D^        : Interrupt"
  rescue RuntimeError
    puts $!.to_s
  end
}
