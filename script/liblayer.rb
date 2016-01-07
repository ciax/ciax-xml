#!/usr/bin/ruby
require 'libmcrsh'
require 'libhexlist'

module CIAX
  # list object can be (Frm,App,Wat,Hex)
  # atrb can have [:top_layer]
  class Layer < CIAX::List
    def initialize(atrb = {})
      atrb[:column] = 4
      super(Config.new, atrb)
      if !atrb.key?(:site)
        mod = Mcr::Man
        @current = 'mcr'
      elsif OPT[:x]
        mod = Hex::List
      else
        mod = Wat::List
      end
      obj = mod.new(@cfg)
      loop do
        ns = m2id(obj.class, -2)
        @list.put(ns, obj)
        obj = obj.sub_list || break
      end
      self
    end

    def ext_shell
      extend(Shell).ext_shell
    end

    # Shell Extension
    module Shell
      include CIAX::List::Shell
      class Jump < LongJump; end

      def ext_shell
        super(Jump)
        @cfg[:jump_layer] = @jumpgrp
        @list.keys.each do|id|
          @list.get(id).ext_shell
          @jumpgrp.add_item(id, id.capitalize + ' mode')
        end
        @current ||= OPT.layer || @list.keys.first
        self
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('elsx')
      begin
        Layer.new(site: ARGV.shift).ext_shell.shell
      rescue InvalidID
        OPT.usage('(opt) [id]')
      end
    end
  end
end
