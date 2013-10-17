#!/usr/bin/ruby
require "libmcrcmd"

module CIAX
  module Mcr
    module Shell
      def init
        @cobj.add_int.set_proc{|ent| cmdexe(ent)}
        self
      end

      private
      def cmdexe(ent)
        if self[:stat] == 'query'
          @cmd_que.push ent.id
          @res_que.pop
        else
          'IGNORE'
        end
      end
    end

    if __FILE__ == $0
      GetOpts.new('rest',{'n' => 'nonstop mode'})
      begin
        cfg=Config.new
        cfg[:db]=Db.new.set('ciax')
        cfg[:app]=App::List.new
        ent=Command.new(cfg).setcmd(ARGV)
        ent.fork[1].ext_shell(ent.record).extend(Shell).init.shell
      rescue InvalidCMD
        $opt.usage("[mcr] [cmd] (par)")
      end
    end
  end
end
