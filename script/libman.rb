#!/usr/bin/ruby
require 'libexe'
require 'libmcrcmd'
require 'libmanview'
require 'libseqlist'

module CIAX
  # Macro Layer
  module Mcr
    # Macro Manager
    class Man < Exe
      attr_reader :sub_list # Used for Layer module
      def initialize(super_cfg)
        super(super_cfg)
        verbose { 'Initiate Manager (option:' + @opt.keys.join + ')' }
        # id = nil -> taken by ARGV
        # pick already includes :command, :version
        _init_dbi2cfg(%i(sites))
        _init_net
        ___init_prompt
        ___init_cmd
        ___init_stat
        ___init_seq
        _opt_mode
      end

      # this is separated for Daemon
      # restart background threads which will be killed by Daemon
      def run
        self
      end

      # Mode Extention by Option
      def ext_local_driver
        require 'libmanproc'
        ext_local_processor
      end

      def ext_local_server
        verbose { 'Initiate Record Archive' }
        @rec_list.refresh_arc_bg
        ___web_cmdlist
        super
      end

      private

      def ___init_prompt
        @sv_stat = (@cfg[:sv_stat] ||= Prompt.new(@id, @opt))
        @par = Parameter.new(list: @sv_stat.get(:list))
      end

      # Initiate for all mode
      def ___init_cmd
        rem = @cobj.add_rem
        rem.cfg[:def_msg] = 'ACCEPT'
        rem.add_sys
        rem.add_int
        rem.add_ext
      end

      def ___init_stat
        @rec_list = RecList.new(@id, @par.list)
        int = @cobj.rem.int
        @stat = ManView.new(@sv_stat, @par, @rec_list, int.valid_keys)
        int.add_par(@par)
      end

      def ___init_seq
        @seq_list = SeqList.new(@rec_list)
        ___init_pre_exe
        ___init_proc_rem_ext
        ___init_proc_rem_int
      end

      def ___init_pre_exe
        @pre_exe_procs << proc do
          @sv_stat.flush(:list, @seq_list.alives).repl(:sid, '')
          @sv_stat.flush(:run).cmt if @sv_stat.upd.get(:list).empty?
          @stat.upd
        end
      end

      def ___init_proc_rem_ext
        # External Command Group
        ext = @cobj.rem.ext
        ext.def_proc do |ent|
          sid = @seq_list.add(ent).id
          @sv_stat.push(:list, sid).repl(:sid, sid)
        end
      end

      def ___init_proc_rem_int
        # Internal Command Group
        @cobj.rem.int.def_proc do |ent|
          @sv_stat.repl(:sid, ent.par[0])
          ent.msg = @seq_list.reply(ent.id) || 'NOSID'
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'cenlrs') do |cfg|
        Man.new(cfg).ext_shell.shell
      end
    end
  end
end
