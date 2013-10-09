#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
require "libhexview"
require "libappsh"

module CIAX
  module Hex
    def self.new(cfg,ash)
      Msg.type?(ash,App::Exe)
      if ['e','s','h','c'].any?{|i| $opt[i]}
        hsh=Hex::Sv.new(cfg,ash,$opt['e'])
      else
        hsh=Hex::Exe.new(cfg,ash.adb)
      end
      hsh
    end

    class Exe < Exe
      def initialize(cfg,adb)
        @adb=type?(cfg[:db],Db)
        id=@adb['site_id']
        super('hex',id,App::ExtCmd.new(cfg))
        stat=App::Status.new.ext_file(id)
        ext_shell(View.new(self,stat))
      end
    end

    class Sv < Exe
      def initialize(cfg,ash,logging=nil)
        super(cfg,ash.adb)
        @output=View.new(ash,ash.stat)
        @cobj['sv'].set_proc{|ent| ash.exe(ent.args)}
        @upd_procs.concat(ash.upd_procs)
        if logging
          logging=Logging.new('hex',self['id'],@adb['version'])
          ash.stat.save_procs << proc{logging.append({'hex' => @output.to_s})}
        end
        ext_server(@adb['port'].to_i+1000)
      end

      private
      def server_input(line)
        return [] if /^(strobe|stat)/ === line
        line.split(' ')
      end

      def server_output
        @output.to_s
      end
    end

    class List < ShList
      def initialize(upper=Config.new)
        super(upper)
        @cfg['app']||=App::List.new
      end

      def new_val(id)
        @cfg[:db]=@cfg[:ldb].set(id)[:app]
        Hex.new(@cfg,@cfg['app'][id])
      end
    end
  end

  if __FILE__ == $0
    ENV['VER']||='init/'
    GetOpts.new('cet')
    begin
      puts Hex::List.new.shell(ARGV.shift)
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
