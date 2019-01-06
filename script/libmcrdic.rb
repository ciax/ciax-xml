#!/usr/bin/ruby
require 'libdic'
require 'libmcrexe'
require 'libmanproc'

module CIAX
  module Mcr
    # Dic for Running Macro
    class Dic < Dic
      attr_reader :cfg, :sub_dic, :man
      # @cfg should have [:sv_stat]
      def initialize(layer_cfg, atrb = Hashx.new)
        super
        # Set [:dev_dic] here for using layer_cfg
        @sub_dic = @cfg[:dev_dic] = Wat::Dic.new(layer_cfg)
        @man = Man.new(@cfg).ext_local_processor(self)
      end

      def get(id)
        return @man if id == 'man'
        super
      end

      def insert(mobj)
        put(mobj.id, mobj)
        mobj
      end

      def interrupt
        _dic.each(&:interrupt)
        self
      end

      def run
        @man.run
        self
      end

      # obsolete, was used for RecDic@cache
      def records
        _dic.inject({}) { |h, obj| h[obj[:id]] = obj.stat }
      end

      # Mcr::Dic specific Shell
      module Shell
        include CIAX::Dic::Shell

        def ext_local_shell
          super
          @cfg[:jump_mcr] = @jumpgrp
          @current = 'man'
          @jumpgrp.add_item(@current, 'manager')
          _dic.each_value { |mobj| __set_jump(mobj) }
          self
        end

        def insert(mobj)
          __set_jump(super)
        end

        private

        def __set_jump(mobj)
          @current = type?(mobj, CIAX::Exe).id
          @jumpgrp.add_item(mobj.id, mobj.cfg[:cid])
          mobj
        end
      end

      class Jump < LongJump; end

      if __FILE__ == $PROGRAM_NAME
        ConfOpts.new('[id]', options: 'cehlns') do |cfg|
          Dic.new(cfg).shell
        end
      end
    end
  end
end
