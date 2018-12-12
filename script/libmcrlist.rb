#!/usr/bin/ruby
require 'liblist'
require 'libmcrexe'
require 'libmanproc'

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
      end

      def get(id)
        return @man if id == 'man'
        ent = super
        @man.sv_stat.repl(:sid, id)
        ent
      end

      # For adding Exe
      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ment) # returns Exe
        mobj = Exe.new(ment) { |e| add(e) }
        put(mobj.id, mobj.run)
        @man.stat.push(mobj.stat)
        mobj
      end

      def interrupt
        _list.each(&:interrupt)
        self
      end

      def run
        @sub_list.run
        @man.run
        ___arc_refresh
        ___web_cmdlist
        self
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

        def ext_local_shell
          super
          @cfg[:jump_mcr] = @jumpgrp
          @current = 'man'
          @jumpgrp.add_item(@current, 'manager')
          _list.each_value { |mobj| __set_jump(mobj) }
          self
        end

        def add(ment)
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
          List.new(cfg).shell
        end
      end
    end
  end
end
