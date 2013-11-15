#!/usr/bin/ruby
require "libmcrcmd"

module CIAX
  module Mcr
    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        cfg=Config.new
        cfg[:db]=Db.new.set('ciax')
        cfg[:app]=App::List.new
        ent=Command.new(cfg).set_cmd(ARGV)
        ent.fork[1].ext_shell.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
