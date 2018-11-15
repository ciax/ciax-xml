#!/usr/bin/ruby
require 'liblist'
require 'libmcrexe'

module CIAX
  module Mcr
    # List for Running Macro
    class List < List
      attr_reader :cfg
      # @cfg should have [:sv_stat]
      def initialize(super_cfg, atrb = Hashx.new)
        super
        @sv_stat = Msg.type?(@cfg[:sv_stat], Prompt)
        @sub_list = @cfg[:dev_list]
        @cfg[:rec_arc].ext_local
        #        @man = self[:list]['0'] = Man.new(@cfg, mcr_list: self)
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent) # returns Exe
        mobj = Exe.new(ent) { |e| add(e) }
        _list[mobj.id] = mobj
        Msg.type?(mobj.start.thread, Threadx::Fork)
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
          self
        end

        def add(ent)
          mobj = super
          @current = mobj.id
          @jumpgrp.add_item(mobj.id, ent[:cid])
          mobj
        end
      end

      class Jump < LongJump; end

      if __FILE__ == $PROGRAM_NAME
        ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
          list = List.new(cfg).ext_shell
          ent = Index.new(list.cfg).add_rem.add_ext.set_cmd(args)
          list.add(ent)
          list.shell
        end
      end
    end
  end
end
