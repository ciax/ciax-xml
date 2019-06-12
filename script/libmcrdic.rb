#!/usr/bin/env ruby
require 'libexedic'
require 'libmcrexe'
require 'libmansh'

module CIAX
  module Mcr
    # ExeDic for Running Macro
    # Local mode only
    class ExeDic < CIAX::ExeDic
      attr_reader :cfg, :sub_dic
      # @cfg should have [:sv_stat]
      def initialize(layer_cfg, atrb = Hashx.new)
        super
        # For server response
        @sv_stat = type?(@cfg[:sv_stat], Prompt).repl(:sid, '')
        @rec_arc = type?(@cfg[:rec_arc], RecArc)
        ___init_man(Man.new(@cfg))
        _init_subdic
      end

      def run
        dbi = @cfg[:dbi]
        ___arc_refresh(dbi)
        ___web_select(dbi)
        get('man').run
        @sub_dic.run
        self
      end

      # k = mcr id (unix time)
      def interrupt
        _dic.each { |k, v| k =~ /[\d]+/ && v.interrupt }
      end

      # obsolete, was used for RecDic@cache
      def records
        _dic.inject({}) { |h, obj| h[obj[:id]] = obj.stat }
      end

      private

      # Set [:sub_dic] here for using layer_cfg
      # Generate sub_dic here for inter layer jump
      def _init_subdic
        obj = @opt.top_layer::ExeDic.new(@cfg, opt: @opt.sub_opt)
        @cfg[:sub_dic] = @sub_dic = obj
        obj = obj.sub_dic until obj.is_a? Wat::ExeDic
        @cfg[:dev_dic] = obj
      end

      def ___init_man(man)
        put('man', man)
        return if @opt.cl?
        ___init_cmd(man.cobj.rem)
        @rec_arc.refresh
      end

      def ___init_cmd(rem)
        rem.ext.def_proc { |ent| __gen_cmd(ent) }
        rem.int.def_proc { |ent| ___man_cmd(ent) }
        rem.get('interrupt').def_proc { interrupt }
      end

      # Macro Generator
      def __gen_cmd(ent)
        mobj = Exe.new(ent) { |e| __gen_cmd(e) }
        put(mobj.id, mobj.run)
        @rec_arc.push(mobj.stat)
      end

      # Macro Manipulator
      def ___man_cmd(ent)
        id = ent.par[0]
        mobj = get(id)
        @sv_stat.repl(:sid, id)
        ent.msg = mobj.exe([ent[:id]]).to_s || 'NOSID'
      end

      # For server initialize
      def ___arc_refresh(dbi)
        verbose { 'Initiate Record Archive' }
        Threadx::Fork.new('RecArc', 'mcr', dbi[:id]) do
          @rec_arc.clear.refresh
        end
      end

      # Making Command Dic JSON file for WebApp
      def ___web_select(dbi)
        verbose { 'Initiate JS Command Dic' }
        jl = Hashx.new(port: @cfg[:port], label: dbi.label)
        jl[:commands] = dbi.web_select
        IO.write(vardir('json') + 'mcr_conf.js', 'var config = ' + jl.to_j)
      end

      # Mcr::ExeDic specific Shell
      module Shell
        include CIAX::ExeDic::Shell

        def ext_shell
          super
          @cfg[:jump_mcr] = @jumpgrp
          _dic.each { |id, mobj| put(id, mobj) }
          @sub_dic.ext_shell
          self
        end

        # For macro manager
        def put(id, mobj)
          cid = type?(mobj, CIAX::Exe).cfg[:cid]
          @jumpgrp.add_form(id, cid)
          @current = id
          super
        end
      end

      class Jump < LongJump; end

      if __FILE__ == $PROGRAM_NAME
        Conf.new('[id]', options: 'cehlns') do |cfg|
          ExeDic.new(cfg)
        end.cui
      end
    end
  end
end
