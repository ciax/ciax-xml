#!/usr/bin/ruby
require "json"
require "readline"

# Prompt should be Array
class Shell
  def initialize(prompt=[])
    cl=Msg::List.new("== Shell Command ==")
    cl.add('q'=>"Quit",'D^'=>"Interrupt")
    Msg.assert(Array === prompt)
    loop {
      line=Readline.readline(prompt.join(''),true)
      break if /^q/ === line
      begin
        puts yield line
      rescue SelectCMD
        puts cl.to_s
      rescue UserError
        puts $!.to_s
      end
    }
  end
end
