#!/usr/bin/ruby
require "json"
require "libfilter"
require "readline"

# db needs these methods
# "prompt","interrupt","quit"
class Shell
  def initialize(db,filter=nil)
    v=Verbose.new("shell")
    out=Filter.new(filter)
    loop {
      line=Readline.readline(db.prompt,true) || db.interrupt
      case line
      when /^q/
        db.quit
        break
      when ''
        puts out.filter(JSON.dump(db.stat))
      else
        begin
          line.split(';').each{|cmd|
            puts yield cmd.split(" ")
          }
        rescue SelectID
          list={}
          list['q']="Quit"
          list['D^']="Interrupt"
          v.list(list,"== Shell Command ==") rescue puts($!)
        rescue
          puts $@.to_s
        end
      end
    }
  end
end
