#!/usr/bin/ruby
require 'libseqcmds'

module CIAX
  # Macro Layer
  module Mcr
    # Sequencer as a Macro Processing (mcrdrv)
    class Sequencer
      include Msg
      attr_reader :cfg, :record, :qry, :id, :title, :sv_stat
      # &submcr_proc for executing asynchronous submacro,
      #    which must returns hash with ['id']
      # ent should have [:sequence]'[:dev_list]
      def initialize(ment, pid = '0', &submcr_proc)
        @cfg = ment
        @dev_list = type?(@cfg[:dev_list], CIAX::Wat::List)
        ___init_record(pid)
        @sv_stat = @cfg[:sv_stat] || Prompt.new(@cfg[:id], @cfg[:opt])
        @submcr_proc = submcr_proc
        @depth = 0
        # For Thread mode
        @qry = Query.new(@record, @sv_stat)
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
        ___upd_sites
        Thread.current[:query] = @qry
        show_fg @record.start
        _sequencer(@cfg, @record.cmt)
      rescue Interrupt
        ___site_interrupt
      rescue CommError, Interlock
        false
      ensure
        show_fg @record.finish + "\n"
      end

      def fork
        Threadx::Fork.new('Macro', 'seq', @id) { play }
      end

      private

      def ___upd_sites
        @cfg[:sites].each { |site| @dev_list.get(site) }
        self
      end

      # macro returns result (true=complete /false=error)
      def _sequencer(cfg, mstat)
        seqary = type?(cfg[:sequence], Array)
        mstat.result = 'busy'
        @depth += 1
        @record[:total_steps] += seqary.size
        # true: exit in the way, false: complete steps
        seqary.all? { |e| _new_step(e, mstat) } && mstat.result != 'comerr'
        # 'upd' passes whether commerr or not
        # result of multiple 'upd' is judged here
      ensure
        @depth -= 1
      end

      # Return false if sequence is broken
      def _new_step(e, mstat)
        step = @record.add_step(e, @depth)
        ___step_trial(e, step, mstat)
      rescue CommError, Interlock
        mstat.result = __set_err(step)
        raise
      ensure
        step.cmt
      end

      # Sub for _new_step()
      def ___step_trial(e, step, mstat)
        show_fg step.title_s
        method('_cmd_' + e[:type]).call(e, step, mstat)
      rescue Retry
        retry
      end

      # Sub for macro()
      def ___site_interrupt
        runary = @sv_stat.get(:run)
        msg("\nInterrupt Issued to running devices #{runary}", 3)
        runary.each do |site|
          @dev_list.get(site).exe(['interrupt'], 'user')
        end
      end

      # Sub for initialize()
      def ___init_record(pid)
        @record = Record.new.ext_local_processor(@cfg)
        @record[:pid] = pid
        @id = @record[:id]
        @title = @record.title_s
        ___init_record_file
      end

      # Do file generation after forked
      def ___init_record_file
        # ext_file must be after ext_rsp which includes time update
        @record.ext_local_file.auto_save
        @record.mklink # Make latest link
        @record.mklink(@id) # Make link to /json
      end
    end

    if __FILE__ == $PROGRAM_NAME
      ConfOpts.new('[proj] [cmd] (par)', options: 'eldnr') do |cfg, args|
        mobj = Index.new(cfg)
        mobj.add_rem.add_ext.dev_list
        ent = mobj.set_cmd(args)
        Sequencer.new(ent).play
      end
    end
  end
end
