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
        _sub_macro(@cfg, @record.cmt)
      rescue Verification
        false
      rescue Interrupt
        ___site_interrupt
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
      def _sub_macro(cfg, mstat)
        seqary = cfg[:sequence]
        ___pre_seq(seqary, mstat)
        seqary.each { |e| break(true) unless _do_step(e, mstat) } || return
        # 'upd' passes whether commerr or not
        # result of multiple 'upd' is judged here
        mstat.result != 'comerr'
      rescue Interlock, CommError
        # For retry
        false
      ensure
        ___post_seq(mstat)
      end

      # Return false if sequence is broken
      def _do_step(e, mstat)
        step = @record.add_step(e, @depth)
        begin
          return true if ___call_step(e, step, mstat)
        rescue Retry
          retry
        end
      rescue Interrupt
        mstat.result = 'interrupted'
        raise
      end

      # Sub for _do_step()
      def ___call_step(e, step, mstat)
        typ = e[:type]
        show_fg step.title_s
        method('_cmd_' + typ).call(e, step, mstat)
      rescue CommError
        mstat.result = step.result = 'comerr'
        raise
      ensure
        show_fg step.result_s if typ != 'mcr'
        step.cmt
      end

      # Sub for macro()
      def ___pre_seq(seqary, mstat)
        @depth += 1
        @record[:status] = 'run'
        @record[:total_steps] += type?(seqary, Array).size
        mstat.result = 'busy'
      end

      def ___post_seq(mstat)
        mstat.result = 'complete' if mstat.result == 'busy'
        @depth -= 1
      end

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
