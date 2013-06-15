#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
require "libhexview"
require "libappsh"

module CIAX
  module Hex
    def self.new(ash)
      type?(ash,App::Exe)
      if ['e','s','h','c'].any?{|i| $opt[i]}
        hsh=Hex::Sv.new(ash,$opt['e'])
      else
        hsh=Hex::Exe.new(ash.adb)
      end
      hsh
    end

    class Exe < Sh::Exe
      def initialize(adb)
        @adb=type?(adb,Db)
        self['layer']='hex'
        self['id']=@adb['site_id']
        cobj=App::ExtCmd.new(adb)
        super(cobj)
        stat=Status::Data.new.ext_file(@adb['site_id'])
        prom=Sh::Prompt.new(self)
        ext_shell(View.new(self,stat),prom)
      end
    end

    class Sv < Exe
      def initialize(ash,logging=nil)
        super(ash.adb)
        @output=View.new(ash,ash.stat)
        @log_proc=UpdProc.new
        @cobj['sv'].def_proc=proc{|item|
          ash.exe(item.cmd)
          @log_proc.upd
        }
        @upd_proc.add{
          ash.stat.load
        }
        if logging
          logging=Logging.new('hex',self['id'],@adb['version'])
          @log_proc.add{logging.append({'hex' => @output.to_s})}
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

    class List < Sh::DevList
      def initialize(al=nil)
        @al=al||App::List.new
        super(Loc::Db.new.list,"#{@al.current}")
      end

      def newsh(id)
        Hex.new(@al[id])
      end
    end
  end

  if __FILE__ == $0
    ENV['VER']||='init/'
    GetOpts.new('ct')
    begin
      puts Hex::List.new[ARGV.shift].shell
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
