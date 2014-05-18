#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
require "libhexview"
require "libappsh"

module CIAX
  module Hex
    # cfg should have [:app_list](App::List)
    def self.new(cfg)
      Hex::Sv.new(cfg)
    end

    class Sv < Exe
      def initialize(ash)
        type?(ash,App::Exe)
        super('hex',ash.id,ash.cobj)
        @mode=ash.mode
        @output=View.new(ash,ash.stat)
        @post_exe_procs.concat(ash.post_exe_procs)
        if $opt['e']
          logging=Logging.new('hex',@id,ash.adb['version'])
          ash.stat.post_upd_procs << proc{logging.append({'hex' => @output.to_s})}
        end
        ext_server(ash.adb['port'].to_i+1000) if ['e','s'].any?{|i| $opt[i]}
        ext_shell(@output)
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

    class List < Site::List
      def initialize(upper=Config.new)
        upper[:app_list]||=App::List.new
        upper[:hex_list]=self
        super
      end

      def new_val(id)
        Hex.new(@cfg[:app_list][id])
      end
    end
  end

  if __FILE__ == $0
    ENV['VER']||='init/'
    GetOpts.new('chset')
    begin
      puts Hex::List.new.shell(ARGV.shift)
    rescue InvalidID
      $opt.usage('(opt) [id]')
    end
  end
end
