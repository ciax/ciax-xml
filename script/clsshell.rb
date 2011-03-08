#!/usr/bin/ruby
require "json"
require "libcls"
require "libxmldoc"
require "libalias"
require "libfilter"
require "readline"

warn "Usage: clsshell [cls] [id] [iocmd] (outcmd)" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
out=Filter.new(ARGV.shift)
al=Alias.new(id)
begin
  doc=XmlDoc.new('cdb',cls)
rescue SelectID
  abort $!.to_s
end
cdb=Cls.new(doc,id,iocmd)
loop {
  begin
    line=Readline.readline(cdb.prompt,true) || cdb.interrupt
    cdb.err?
    case line
    when /^q/
      break
    when ''
      puts out.filter(JSON.dump(cdb.stat))
    else
      line.split(';').each{|cmd|
        stm=al.alias(cmd).split(' ')
        cdb.dispatch(stm){|s|s}
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
