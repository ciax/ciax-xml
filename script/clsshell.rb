#!/usr/bin/ruby
require "json"
require "libfilter"
require "libcls"
require "libxmldoc"
require "readline"

warn "Usage: clsshell [cls] [id] [iocmd] (outcmd) (incmd)" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
out=Filter.new(ARGV.shift)
inp=Filter.new(ARGV.shift)
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
        stm=inp.filter(cmd).split(' ')
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
