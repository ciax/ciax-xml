#!/usr/bin/ruby
require "libcls"
require "readline"

warn "Usage: clsshell [cls] [id] [iocmd]" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
cdb=Cls.new(cls,id,iocmd)

loop {
  begin
    if line=Readline.readline(cdb.prompt,true)
      cdb.err?
      case line
      when /^q/
        break
      when ''
        puts cdb.stat
      else
        line.split(';').each{|stm|
          cdb.dispatch(stm.split(' ')){|s|s}
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
