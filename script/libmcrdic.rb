#!/usr/bin/env ruby
require 'libdic'
require 'libmcrexe'
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
        @man = Man.new(@cfg)
        put('man', @man)
        # For element of Layer
        @sub_dic = type?(@cfg[:dev_dic], Wat::Dic)
        @rec_arc = type?(@cfg[:rec_arc], RecArc)
        # For server response
        @sv_stat = type?(@cfg[:sv_stat], Prompt).repl(:sid, '')
        ___init_local
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

      def ___init_local
        @rec_arc.ext_local.refresh
        ___init_log
        ___init_procs
        self
      end

      def ___init_log
        return unless @cfg[:opt].mcr_log?
        @rec_arc.ext_save
        @man.cobj.rem.ext_input_log
      end

      def ___init_procs
        ___init_pre_exe
        ___init_proc_def
        ___init_proc_sys
      end

      def ___init_pre_exe
        @man.pre_exe_procs << proc do
          @sv_stat.repl(:sid, '')
          @sv_stat.flush(:run).cmt if @sv_stat.get(:list).empty?
        end
      end

      def ___init_proc_def
        rem = @man.cobj.rem
        rem.ext.def_proc { |ent| ___gen_cmd(ent) }
        rem.int.def_proc { |ent| ___man_cmd(ent) }
      end

      # Macro Generator
      def ___gen_cmd(ent)
        mobj = Exe.new(ent) { |e| ___gen_cmd(e) }
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

      def ___init_proc_sys
        @man.cobj.get('interrupt').def_proc do
          each { |k, v| k =~ /[\d]+/ && v.interrupt }
        end
      end

      # For server initialize
      def ___arc_refresh
        verbose { 'Initiate Record Archive' }
        Threadx::Fork.new('RecArc', 'mcr', @cfg[:dbi][:id]) do
          @rec_arc.clear.refresh
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
