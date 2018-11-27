#!/usr/bin/ruby
require 'liblist'
require 'libmcrexe'
require 'libmcrmandrv'

module CIAX
  module Mcr
    # List for Running Macro
    class List < List
      attr_reader :cfg, :sub_list, :man
      # @cfg should have [:sv_stat]
      def initialize(super_cfg, atrb = Hashx.new)
        super
        @sv_stat = Msg.type?(@cfg[:sv_stat], Prompt)
        @sub_list = @cfg[:dev_list] = Wat::List.new(@cfg)
        @rec_arc = @cfg[:rec_arc].ext_local.refresh
        @rec_arc.ext_save if @cfg[:opt].mcr_log?
        @man = Man.new(@cfg, mcr_list: self).ext_local_driver
      end

      def exe(args)
        @man.exe(args)
        self
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent) # returns Exe
        mobj = Exe.new(ent) { |e| add(e) }
        _list[mobj.id] = mobj.run
        @rec_arc.push(mobj.stat)
        mobj
      end

      def interrupt
        _list.each(&:interrupt)
        self
      end

      def run
        ___arc_refresh
        ___web_cmdlist
        super
      end

      def ext_shell
        extend(Shell).ext_shell
      end

      private

      def ___arc_refresh
        verbose { 'Initiate Record Archive' }
        Threadx::Fork.new('RecArc', 'mcr', @id) do
          @rec_arc.clear.refresh
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
          @man.ext_shell
          self
        end

        def add(ent)
          __set_jump(super)
        end

        private

        def __set_jump(mobj)
          @current = type?(mobj, Exe).id
          @jumpgrp.add_item(mobj.id, mobj.cfg[:cid])
          mobj
        end
      end

      class Jump < LongJump; end

      if __FILE__ == $PROGRAM_NAME
        require 'liblayer'
        ConfOpts.new('[id]', options: 'cehlns') do |rcfg, args|
          Layer.new(rcfg) do |cfg|
            List.new(cfg).exe(args)
          end.ext_shell.shell
        end
      end
    end
  end
end
