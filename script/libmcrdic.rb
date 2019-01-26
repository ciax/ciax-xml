#!/usr/bin/ruby
require 'libdic'
require 'libmcrexe'

module CIAX
  module Mcr
    # Dic for Running Macro
    class Dic < CIAX::Dic
      attr_reader :cfg, :sub_dic
      # @cfg should have [:sv_stat]
      def initialize(layer_cfg, atrb = Hashx.new)
        super
        @cfg[:mcr_dic] = self
        # Set [:dev_dic] here for using layer_cfg
        @sub_dic = @cfg[:dev_dic] ||= Wat::Dic.new(layer_cfg)
      end

      # For new macro
      def push(mobj)
        put(mobj.id, mobj)
      end

      def interrupt
        _dic.each(&:interrupt)
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
          _dic.each { |id, mobj| put(id, mobj) }
          self
        end

        # For macro manager
        def put(id, mobj)
          cid = type?(mobj, CIAX::Exe).cfg[:cid]
          @jumpgrp.add_item(id, cid)
          @current = id
          self
        end
      end

      class Jump < LongJump; end

      if __FILE__ == $PROGRAM_NAME
        require 'libmanproc'
        ConfOpts.new('[id]', options: 'cehlns') do |cfg|
          dic = Dic.new(cfg)
          dic.put('man', Man.new(dic.cfg)).shell
        end
      end
    end
  end
end
