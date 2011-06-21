#!/usr/bin/ruby
require "json"
require "readline"

# db needs these methods
# "prompt","interrupt","quit"
# Param: db, input filter(proc), output filter(proc)
class Shell
  def initialize(db,inpf=nil,outf=nil)
    v=Verbose.new("shell")
    loop {
      line=Readline.readline(db.prompt,true)
      case line
      when nil
        puts db.interrupt
      when /^q/
        break
      when ''
        puts outf ? outf.call(db.stat) : db.stat
      else
        begin
          line.split(';').each{|cmd|
            cmda=cmd.split(" ")
            puts inpf ? inpf.call(cmda) : cmda
          }
        rescue SelectID
          list={}
          list['q']="Quit"
          list['D^']="Interrupt"
          v.list(list,"== Shell Command ==") rescue puts($!)
        rescue UserError
          puts $!.to_s
        end
      end
    }
  end
end
