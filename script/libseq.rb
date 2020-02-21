#!/usr/bin/env ruby
require 'libseqcmds'
require 'libseqqry'

module CIAX
  # Macro Layer
  module Mcr
    # Sequencer as a Macro Processing (mcrdrv)
    class Sequencer
      include Msg
      attr_reader :record, :qry, :id, :title, :sv_stat
      # rem = Remote domain in Command
      # &submcr_proc for executing asynchronous submacro,
      #    which must returns hash with ['id']
      # ent should have [:sequence],[:dev_dic],[:pid]
      def initialize(cfg, rem, &submcr_proc)
        @opt = type?(cfg, Config)[:opt]
        ___init_record(cfg)
        @dev_dic = type?(cfg[:dev_dic], Wat::ExeDic)
        @sv_stat = type?(cfg[:sv_stat], Prompt).repl(:sid, @id)
        @seq = type?(cfg[:sequence], Array)
        @submcr_proc = submcr_proc
        @depth = 0
        # For Thread mode
        @qry = Reply.new(@record, @sv_stat, rem)
      end

      # For prompt '(stat) [option]'
      def to_v
        @qry.to_v
      end

      def reply(str)
        @qry.reply(str)
      end

      # Start the macro
      def play
        ___pre_play
        _sequencer(@seq, @record)
      rescue CommError, Verification
        nil
      rescue Interrupt
        ___site_interrupt
      ensure
        ___post_play
      end

      private

      def ___pre_play
        @dev_dic.init_sites if @dev_dic
        Thread.current[:query] = @qry.clear
        show_fg @record.start
        @sv_stat.push(:list, @id)
      end

      def ___post_play
        show_fg format("%s\n", @record.finish)
        @sv_stat.erase(:list, @id)
        # Don't remove record link. Otherwise OPGUI makes error
        # @record.rmlink(@id) if @opt.mcr_log?
      end

      # macro returns result (true=complete /false=error)
      def _sequencer(seq, mstat)
        mstat.result = 'busy'
        @depth += 1
        # true: exit in the way, false: complete steps
        @record[:total_steps] += seq.size
        seq.all? { |e| _new_step(e, mstat) }
        # 'upd' passes whether commerr or not
        # result of multiple 'upd' is judged here
        mstat.result.gsub!('busy', 'complete')
      rescue Verification
        mstat.result = 'failed'
        raise
      ensure
        @depth -= 1
      end

      # Return false if sequence is broken
      def _new_step(e, mstat)
        step = @record.add_step(e, @depth)
        ___step_trial(step, mstat)
      rescue CommError, Interlock, Interrupt, InvalidARGS
        mstat.result = __set_err(step)
        raise
      end

      # Sub for _new_step()
      def ___step_trial(step, mstat)
        show_fg step.title_s
        # Returns T/F
        method('_cmd_' + step[:type]).call(step, mstat)
      rescue Retry
        retry
      end

      # Sub for macro()
      def ___site_interrupt
        @dev_dic.interrupt(@sv_stat.get(:run)) if @dev_dic
        @sv_stat.flush(:run).cmt
        nil
      end

      # Sub for initialize()
      def ___init_record(cfg)
        @record = Record.new.ext_local.ext_processor(cfg)
        @id = @record[:id]
        @title = @record.title_s
        ___init_record_file
      end

      # Do file generation after forked
      def ___init_record_file
        return unless @opt.mcr_log?
        # ext_file must be after ext_rsp which includes time update
        @record.ext_local.ext_file.ext_save
        @record.mklink # Make latest link
        @record.mklink(@id) # Make link to /json
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Conf.new('[proj] [cmd] (par)', options: 'eldnr') do |cfg|
        atrb = { dev_dic: cfg.opt.top_layer::ExeDic.new(cfg) }
        rem = Index.new(cfg, atrb).add_rem
        rem.add_int
        ent = rem.add_ext.set_cmd(cfg.args)
        Sequencer.new(ent, rem).play
      end
    end
  end
end
