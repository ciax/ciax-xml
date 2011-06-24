#!/usr/bin/ruby
require "json"
require "readline"

# db needs these methods
# "prompt","interrupt","quit"
# Param: db, input filter(proc), output filter(proc)
class Shell
  def initialize(pary=[])
    v=Verbose.new("shell")
    v.add("== Shell Command ==")
    v.add('q'=>"Quit",'D^'=>"Interrupt")
    loop {
      line=Readline.readline(pary.join(''),true)
      break if /^q/ === line
      begin
        yield line
      rescue SelectID
        puts v
      rescue UserError
        puts $!.to_s
      end
    }
  end
end
