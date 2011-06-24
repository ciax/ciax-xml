#!/usr/bin/ruby
require "json"
require "readline"

# db needs these methods
# "prompt","interrupt","quit"
# Param: db, input filter(proc), output filter(proc)
class Shell
  def initialize(pary=[])
    v=Verbose.new("shell")
    loop {
      line=Readline.readline(pary.join(''),true)
      break if /^q/ === line
      begin
        yield line
      rescue SelectID
        list={}
        list['q']="Quit"
        list['D^']="Interrupt"
        v.list(list,"== Shell Command ==") rescue puts($!)
      rescue UserError
        puts $!.to_s
      end
    }
  end
end
