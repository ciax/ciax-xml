#!/usr/bin/ruby
require "json"
require "libshell"
require "libcls"
require "libxmldoc"

warn "Usage: clsshell [cls] [id] [iocmd] (outcmd)" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
sh=Shell.new(ARGV.shift)
begin
  doc=XmlDoc.new('cdb',cls)
rescue SelectID
  abort $!.to_s
end
cdb=Cls.new(doc,id,iocmd)
loop {
  begin
    line=sh.input(cdb.prompt){cdb.interrupt}
    cdb.err?
    case line
    when /^q/
      break
    when ''
      puts sh.filter(JSON.dump(cdb.stat))
    else
      line.split(';').each{|stm|
        cdb.dispatch(stm.split(' ')){|s|s}
      }
    end
  rescue SelectID
    puts $!.to_s
    puts "== Shell Command =="
    puts " q         : Quit"
    puts " D^        : Interrupt"
  rescue RuntimeError
    puts $!.to_s
  end
}
