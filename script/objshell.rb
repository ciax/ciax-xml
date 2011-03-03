#!/usr/bin/ruby
require "libcls"
require "libalias"
require "libobjstat"
require "libmodview"
require "readline"
include ModView

warn "Usage: objshell [cls] [obj] [id] [iocmd]" if ARGV.size < 1

cls=ARGV.shift
obj=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
oc=Alias.new(obj)
os=ObjStat.new(obj)
cdb=Cls.new(cls,id,iocmd)

loop {
  begin
    if line=Readline.readline(cdb.prompt,true)
      case line
      when /^q/
        break
      when ''
        puts view(os.get_view(cdb.stat))
      else
        line.split(';').each{|stm|
          cdb.dispatch(stm.split(' ')){|c| oc.alias(c)}
        }
      end
    else
      cdb.interrupt
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
