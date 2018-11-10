#!/usr/bin/ruby
require 'liblist'
require 'libmcrman'

module CIAX
  module Mcr
    # List for Running Macro/Manager
    class List < List
      attr_reader :cfg
      # level can be Layer or Site
      # @cfg should have [:sv_stat]
      # @cfg[:db] associated site/layer should be set
      def initialize(super_cfg, atrb = Hashx.new)
        #      @cfg = super_cfg.gen(self).update(atrb)
        #      @cfg[:jump_groups] ||= []
        #      super(m2id(@cfg[:obj].class, -2))
        #      verbose { 'Initiate List (option:' + @cfg[:opt].keys.join + ')' }
        #      self[:list] = Hashx.new
        super
        @sv_stat = Msg.type?(@cfg[:sv_stat], Prompt)
        @sv_stat.upd_procs << proc { |ss| ss.repl(:sid, '') }
        @man = self[:list]['0'] = Man.new(@cfg, mcr_list: self)
      end

      # this is separated for Daemon
      # restart background threads which will be killed by Daemon
      def run
        @sub_list.run
        self
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(exe) # returns Exe
        _list[exe.id] = exe
        @cfg[:rec_arc].push(exe.stat)
        @jumpgrp.add_item(exe.id, exe.id)
        exe
      end

      def ext_shell
        extend(CIAX::List::Shell).ext_shell(Jump)
        @cfg[:jump_mcr] = @jumpgrp
        @man.ext_shell
        @current = '0'
        self
      end

      class Jump < LongJump; end

      if __FILE__ == $PROGRAM_NAME
        ConfOpts.new('[id]', options: 'cehls') do |cfg, args|
          List.new(cfg, sites: args).ext_shell.shell
        end
      end
    end
  end
end
