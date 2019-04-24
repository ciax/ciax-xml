#!/usr/bin/env ruby
require 'libseqcmds'
require 'libseqqry'

module CIAX
  # Macro Layer
  module Mcr
    # Sequencer as a Macro Processing (mcrdrv)
    class Sequencer
      include Msg
      attr_reader :cfg, :record, :qry, :id, :title, :sv_stat
      # &submcr_proc for executing asynchronous submacro,
      #    which must returns hash with ['id']
      # ent should have [:sequence],[:dev_dic],[:pid]
      def initialize(ment, &submcr_proc)
        @cfg = ment
        @opt = @cfg[:opt]
        @dev_dic = type?(@cfg[:dev_dic], Wat::ExeDic)
        ___init_record
        @sv_stat = type?(@cfg[:sv_stat], Prompt)
        @submcr_proc = submcr_proc
        @depth = 0
        # For Thread mode
        @qry = Query.new(@record, @sv_stat, @cfg[:valid_keys] || [])
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
        _sequencer(@cfg, @record.cmt)
      rescue CommError, Verification
        safe_exit
      rescue Interrupt
        ___site_interrupt
      ensure
        ___post_play
      end

      private

      def ___pre_play
        @dev_dic.init_sites if @dev_dic
        Thread.current[:query] = @qry
        show_fg @record.start
        @sv_stat.push(:list, @id).repl(:sid, @id)
      end

      def ___post_play
        show_fg @record.finish + "\n"
        @sv_stat.erase(:list, @id)
        @record.rmlink(@id) if @opt.mcr_log?
      end

      # macro returns result (true=complete /false=error)
      def _sequencer(cfg, mstat)
        mstat.result = 'busy'
        @depth += 1
        # true: exit in the way, false: complete steps
        ___get_seq(cfg).all? { |e| _new_step(e, mstat) }
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
        res = ___step_trial(step, mstat)
        step.cmt
        res
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
        8
      end

      # Sub for initialize()
      def ___init_record
        @record = Record.new.ext_local_processor(@cfg)
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

      def ___get_seq(cfg)
        seq = type?(cfg[:sequence], Array)
        @record[:total_steps] += seq.size
        seq
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Conf.new('[proj] [cmd] (par)', options: 'eldnr') do |cfg|
        ent = Index.new(cfg, Atrb.new(cfg)).add_rem.add_ext.set_cmd(cfg.args)
        Sequencer.new(ent).play
      end
    end
  end
end
