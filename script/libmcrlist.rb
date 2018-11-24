#!/usr/bin/ruby
require 'liblist'
require 'libmcrexe'

module CIAX
  module Mcr
    # List for Running Macro
    class List < List
      attr_reader :cfg, :sub_list
      # @cfg should have [:sv_stat]
      def initialize(super_cfg, atrb = Hashx.new)
        super
        super_cfg[:layer_type] = 'mcr'
        @sv_stat = Msg.type?(@cfg[:sv_stat], Prompt)
        @sub_list = @cfg[:dev_list] = Wat::List.new(@cfg)
        @cfg[:rec_arc].ext_local
        @cobj = Index.new(@cfg).add_rem.add_ext
        #        @man = self[:list]['0'] = Man.new(@cfg, mcr_list: self)
      end

      def exe(args)
        add(@cobj.set_cmd(args))
        self
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent) # returns Exe
        mobj = Exe.new(ent) { |e| add(e) }
        _list[mobj.id] = mobj.run
        @cfg[:rec_arc].push(mobj.stat)
        mobj
      end

      def interrupt
        _list.each(&:interrupt)
        self
      end

      def ext_shell
        extend(Shell).ext_shell
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

        def add(ent)
          __set_jump(super)
        end

        private

        def __set_jump(mobj)
          @current = mobj.id
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
