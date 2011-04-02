#!/usr/bin/ruby
require "json"
require "libfilter"
require "readline"

# db needs these methods
# "prompt","interrupt","quit"
class Shell
  def initialize(db,stat,filter=nil)
    out=Filter.new(filter)
    loop {
      begin
        line=Readline.readline(db.prompt,true) || db.interrupt
        case line
        when /^q/
          db.quit
          break
        when ''
        else
          begin
            line.split(';').each{|cmd|
              stat=yield cmd.split(" ")
            }
          rescue SelectID
            puts $!.to_s
            puts "== Shell Command =="
            puts " q         : Quit"
            puts " D^        : Interrupt"
          end
        end
        puts out.filter(JSON.dump(stat))
      rescue
        puts $!.to_s
      end
    }
  end
end
