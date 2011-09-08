#!/usr/bin/ruby
require "json"
require "readline"

# Prompt should be Array
class Shell
  def initialize(prompt=[])
    cl=CmdList.new("== Shell Command ==")
    cl.add('q'=>"Quit",'D^'=>"Interrupt")
    Msg.assert(Array === prompt)
    loop {
      line=Readline.readline(prompt.join(''),true)
      break if /^q/ === line
      begin
        puts yield line
      rescue SelectID
        puts v
      rescue UserError
        puts $!.to_s
      end
    }
  end
end
