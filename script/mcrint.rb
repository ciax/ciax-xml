#!/usr/bin/ruby
require "libmcrdb"
require "libmcrobj"
require 'libshell'

id=ARGV.shift
ARGV.clear
begin
  ac=McrObj.new
  mdb=McrDb.new(id)
  par=Param.new(mdb)
rescue SelectID
  warn "Usage: #{$0} [mcr]"
  Msg.exit
end
Shell.new('mcr>'){|cmd|
  unless cmd.empty?
    par.set(cmd)
    Thread.new{
      Thread.pass
      ac.mcr(par)
    }
  end
  ac
}
