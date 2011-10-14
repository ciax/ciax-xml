#!/usr/bin/ruby
require "readline"

# Prompt should be Array
class Shell
  def initialize(prompt='')
    cl=Msg::List.new("== Shell Command ==")
    cl.add('q'=>"Quit",'D^'=>"Interrupt")
    loop {
      line=Readline.readline(prompt,true)||'interrupt'
      break if /^q/ === line
      begin
        puts (yield line.split(' ')).to_s
      rescue SelectCMD
        puts cl.to_s
      rescue UserError
        puts $!.to_s
      end
    }
  end
end
