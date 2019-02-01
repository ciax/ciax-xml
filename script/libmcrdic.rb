#!/usr/bin/env ruby
require 'libdic'
require 'libmansh'

module CIAX
  module Mcr
    # Dic for Running Macro
    class Dic < CIAX::Dic
      attr_reader :cfg, :sub_dic
      # @cfg should have [:sv_stat]
      def initialize(layer_cfg, atrb = Hashx.new)
        atrb.update(Atrb.new(layer_cfg))
        super
        # Set [:dev_dic] here for using layer_cfg
        @man = Man.new(@cfg, mcr_dic: self)
        put('man', @man)
        # For element of Layer
        @sub_dic = type?(@cfg[:dev_dic], Wat::Dic)
      end

      def run
        ___arc_refresh
        ___web_select(@man.run.port)
        @sub_dic.run
        self
      end

      # obsolete, was used for RecDic@cache
      def records
        _dic.inject({}) { |h, obj| h[obj[:id]] = obj.stat }
      end

      private

      # For server initialize
      def ___arc_refresh
        verbose { 'Initiate Record Archive' }
        Threadx::Fork.new('RecArc', 'mcr', @cfg[:dbi][:id]) do
          @cfg[:rec_arc].clear.refresh
        end
      end

      # Making Command Dic JSON file for WebApp
      def ___web_select(port)
        verbose { 'Initiate JS Command Dic' }
        dbi = @cfg[:dbi]
        jl = Hashx.new(port: port, label: dbi.label)
        jl[:commands] = dbi.web_select
        IO.write(vardir('json') + 'mcr_conf.js', 'var config = ' + jl.to_j)
      end

      # Mcr::Dic specific Shell
      module Shell
        include CIAX::Dic::Shell

        def ext_local_shell
          super
          @cfg[:jump_mcr] = @jumpgrp
          _dic.each { |id, mobj| put(id, mobj) }
          @sub_dic.ext_local_shell
          self
        end

        # For macro manager
        def put(id, mobj)
          cid = type?(mobj, CIAX::Exe).cfg[:cid]
          @jumpgrp.add_item(id, cid)
          @current = id
          super
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
