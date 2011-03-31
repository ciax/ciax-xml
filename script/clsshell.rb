#!/usr/bin/ruby
require "json"
require "libcls"
require "libfrm"
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
      cdb.quit
      break
    when ''
      puts out.filter(JSON.dump(cdb.stat))
    else
      begin
        line.split(';').each{|cmd|
          stm=al.alias(cmd.split(' '))
          cdb.dispatch(stm)
        }
      rescue SelectID
        puts $!.to_s
        puts "== Shell Command =="
        puts " q         : Quit"
        puts " D^        : Interrupt"
      end
    end
  rescue
    puts $!.to_s
  end
}
