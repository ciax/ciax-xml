#!/usr/bin/ruby
require "json"
require "libcls"
require "libxmldoc"
require "readline"

warn "Usage: clsshell [cls] [id] [iocmd] (outcmd)" if ARGV.size < 1

cls=ARGV.shift
id=ARGV.shift
iocmd=ARGV.shift
ocmd=ARGV.shift
begin
  doc=XmlDoc.new('cdb',cls)
rescue SelectID
  abort $!.to_s
end
cdb=Cls.new(doc,id,iocmd)
loop {
  begin
    if line=Readline.readline(cdb.prompt,true)
      cdb.err?
      case line
      when /^q/
        break
      when ''
        if ocmd != ''
          IO.popen(ocmd,'r+'){|f|
            f.write(JSON.dump(cdb.stat))
            f.close_write
            puts f.read
          }
        else
          puts cdb.stat
        end
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
