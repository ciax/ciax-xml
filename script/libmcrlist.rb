#!/usr/bin/ruby
require 'liblist'
require 'libmcrexe'
require 'libmcrmanproc'

module CIAX
  module Mcr
    # List for Running Macro
    class List < List
      attr_reader :cfg, :sub_list, :man
      # @cfg should have [:sv_stat]
      def initialize(super_cfg, atrb = Hashx.new)
        super
        @sub_list = @cfg[:dev_list] = Wat::List.new(@cfg)
        @man = Man.new(@cfg).ext_local_processor(self)
        @man.stat.ext_local.refresh
        @man.stat.ext_save if @cfg[:opt].mcr_log?
        put(@man)
      end

      def get(id)
        ent = super
        @man.sv_stat.repl(:sid, id)
        ent
      end

      # For adding Man
      def put(mobj)
        super(mobj.id, mobj)
      end

      # For adding Exe
      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent) # returns Exe
        mobj = Exe.new(ent) { |e| add(e) }
        put(mobj.run)
        @man.stat.push(mobj.stat)
        mobj
      end

      def interrupt
        _list.each(&:interrupt)
        self
      end

      def run
        @sub_list.run
        ___arc_refresh
        ___web_cmdlist
        self
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      private

      def ___arc_refresh
        verbose { 'Initiate Record Archive' }
        Threadx::Fork.new('RecArc', 'mcr', @id) do
          @man.stat.clear.refresh
        end
      end

      # Making Command List JSON file for WebApp
      def ___web_cmdlist
        verbose { 'Initiate JS Command List' }
        dbi = @cfg[:dbi]
        jl = Hashx.new(port: @port, commands: dbi.list, label: dbi.label)
        IO.write(vardir('json') + 'mcr_conf.js', 'var config = ' + jl.to_j)
      end

      # Mcr::List specific Shell
      module Shell
        include CIAX::List::Shell

        def ext_shell
          super(Jump)
          @cfg[:jump_mcr] = @jumpgrp
          _list.each_value { |mobj| __set_jump(mobj) }
          self
        end

        def put(mobj)
          __set_jump(mobj)
          super
        end

        private

        def __set_jump(mobj)
          @current = type?(mobj, CIAX::Exe).id
          @jumpgrp.add_item(mobj.id, mobj.cfg[:cid] || 'manager')
          mobj
        end
      end

      class Jump < LongJump; end

      if __FILE__ == $PROGRAM_NAME
        ConfOpts.new('[id]', options: 'cehlns') do |cfg|
          List.new(cfg).ext_shell.shell
        end
      end
    end
  end
end
