#!/usr/bin/ruby
require 'librecord'
module CIAX
  module Mcr
    class View < DataH
      def initialize(id,valid_keys)
        super('mcr')
        @valid_keys = valid_keys
        @id = id
      end

      def to_v
        idx = 1
        page = ['<<< ' + Msg.color("Active Macros [#{@id}]", 2) + ' >>>']
        @data.each do|id, rec|
          title = "[#{idx}] (#{id})(by #{rec['cid']})"
          msg = "#{rec['cid']} [#{rec['step']}/#{rec['total_steps']}]"
          msg << "(#{rec['stat']})"
          msg << optlist(rec.last['option']) if rec.last
          page << Msg.item(title, msg)
          idx += 1
        end
        page.join("\n")
      end

      def upd_core
        @valid_keys.each do |id|
          put(id,get_rec(id)) unless @data.key?(id)
        end
        values.each{ |rec| rec.upd }
        self
      end

      def get_rec(id)
        Record.new(id).ext_file
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libgetopts'
      unless ARGV.empty?
        puts View.new('test',ARGV).upd.to_v
      else
        OPT.usage('[id] ..')
      end
    end
  end
end
