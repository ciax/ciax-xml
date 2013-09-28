#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
require "libhexview"
require "libappsh"

module CIAX
  module Hex
    def self.new(ash)
      Msg.type?(ash,App::Exe)
      if ['e','s','h','c'].any?{|i| $opt[i]}
        hsh=Hex::Sv.new(ash,$opt['e'])
      else
        hsh=Hex::Exe.new(ash.adb)
      end
      hsh
    end

    class Exe < Exe
      def initialize(adb)
        @adb=type?(adb,Db)
        id=@adb['site_id']
        super('hex',id,App::ExtCmd.new(adb))
        stat=App::Status.new.ext_file(id)
        ext_shell(View.new(self,stat))
      end
    end

    class Sv < Exe
      def initialize(ash,logging=nil)
        super(ash.adb)
        @output=View.new(ash,ash.stat)
        @cobj['sv'].cfg[:def_proc]=proc{|ent| ash.exe(ent.args)}
        @upd_proc.concat(ash.upd_proc)
        if logging
          logging=Logging.new('hex',self['id'],@adb['version'])
          ash.stat.save_proc << proc{logging.append({'hex' => @output.to_s})}
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
      attr_reader :al
      def initialize
        @al=App::List.new
        super{|id| Hex.new(@al[id])}
        update_items(Loc::Db.new.list)
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
