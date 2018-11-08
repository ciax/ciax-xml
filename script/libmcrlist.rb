#!/usr/bin/ruby
require 'liblist'
require 'libmcrman'

module CIAX
  module Mcr
    # List which provides records
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
        @sv_stat.upd_procs << proc do |ss|
          ss.flush(:list, alives).repl(:sid, '')
        end
        @man = self[:list]['0'] = Man.new(@cfg)
      end

      def run
        @sub_list.run
        self
      end

      def get(id)
        mobj = super
        @current = mobj.id
        mobj
      end

      # pid is Parent ID (user=0,mcr_id,etc.) which is source of command issued
      def add(ent) # returns Sequencer
        seq = Exe.new(ent) { |e| add(e) }.seq
        @sv_stat.push(:list, seq.id).repl(:sid, seq.id)
        @cfg[:rec_arc].push(seq.record)
        @jumpgrp.add_item(id, id.capitalize + ' seq')
        seq
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
