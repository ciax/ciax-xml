#!/usr/bin/ruby
require 'libmcrsh'
require 'libhexlist'

module CIAX
  # list object can be (Frm,App,Wat,Hex)
  # atrb can have [:top_layer]
  class Layer < CIAX::List
    def initialize(optstr)
      opt = GetOpts.new
      cfg = Config.new(column: 4, option: opt.parse(optstr))
      super(cfg)
      if opt[:m]
        mod = Mcr::Man
        usage = '[proj] [cmd] (par)'
      else
        @cfg[:site] = ARGV.shift
        mod = opt[:x] ? Hex::List : Wat::List
        usage = '(opt) [id]'
      end
      obj = mod.new(@cfg)
      loop do
        ns = m2id(obj.class, -2)
        @list.put(ns, obj)
        obj = obj.sub_list || break
      end
    rescue InvalidARGS
      opt.usage(usage)
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
        @current = @cfg[:option].layer || @list.keys.first
        self
      end
    end

    Layer.new('elsx').ext_shell.shell if __FILE__ == $PROGRAM_NAME
  end
end
