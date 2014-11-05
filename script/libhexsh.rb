#!/usr/bin/ruby
# Ascii Pack
require "libhexview"
require "libwatsh"

module CIAX
  module Hex
    # cfg should have [:wat_list](Wat::List)
    def self.new(wsh)
      Hex::Sv.new(wsh)
    end

    class Sv < Exe
      def initialize(wsh)
        type?(wsh,Wat::Exe)
        super('hex',wsh.id)
        @cobj.svdom.replace wsh.cobj.svdom
        @mode=wsh.mode
        @output=View.new(wsh,wsh.stat)
        @post_exe_procs.concat(wsh.post_exe_procs)
        if $opt['e']
          logging=Logging.new('hex',{'id' => @id,'ver' => wsh.adb['version']})
          wsh.stat.post_upd_procs << proc{logging.append({'hex' => @output.to_s})}
        end
        ext_server(wsh.adb['port'].to_i+1000) if ['e','s'].any?{|i| $opt[i]}
        ext_shell
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
      def initialize(upper=nil)
        super
        @cfg[:level]='hex'
        @cfg[:wat_list]||=Wat::List.new
        @cfg[:hex_list]=self
      end

      def add(id)
        Hex.new(@cfg[:wat_list][id])
      end
    end

    if __FILE__ == $0
      ENV['VER']||='initialize'
      GetOpts.new('chset')
      begin
        puts List.new.shell(ARGV.shift)
      rescue InvalidID
        $opt.usage('(opt) [id]')
      end
  end
  end
end
