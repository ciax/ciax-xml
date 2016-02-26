#!/usr/bin/ruby
require 'libmcrfunc'

module CIAX
  # Macro Layer
  module Mcr
    # Sequencer
    class Seq
      include Msg
      include Func
      attr_reader :cfg, :record, :qry, :id, :title
      # &submcr_proc for executing asynchronous submacro,
      #    which must returns hash with ['id']
      # ent should have [:sequence]'[:dev_list]
      def initialize(ment, pid = '0', valid_keys = [], &submcr_proc)
        @cfg = ment
        type?(@cfg[:dev_list], CIAX::Wat::List)
        @record = Record.new.ext_file.auto_save.mklink # Make latest link
        @record.ext_rsp(@cfg)
        @record[:pid] = pid
        @id = @record[:id]
        @sv_stat = (@cfg[:sv_stat] || Prompt.new('mcr', @id))
        @sv_stat.add_array(:run)
        @sv_stat.add_str(:sid, @id)
        @title = @record.title
        @submcr_proc = submcr_proc
        @depth = 0
        # For Thread mode
        @qry = Query.new(@record, @sv_stat, valid_keys)
        @sv_stat.up(:nonstop) if @cfg[:option][:n]
      end

      # For prompt '(stat) [option]'
      def to_v
        @qry.to_v
      end

      def reply(str)
        @qry.reply(str)
      end

      def macro
        Thread.current[:obj] = self
        _show(@record.start)
        sub_macro(upd_sites + @cfg[:sequence], @record)
      rescue Interrupt
        msg("\nInterrupt Issued to running devices #{@sv_stat.get(:run)}", 3)
        @sv_stat.get(:run).each do|site|
          @cfg[:dev_list].get(site).exe(['interrupt'], 'user')
        end
      rescue Verification
        false
      ensure
        _show(@record.finish + "\n")
      end

      def fork
        Threadx.new("Macro(#{@id})", 10) { macro }
      end

      private

      # macro returns result (true=complete /false=error)
      def sub_macro(seqary, mstat)
        @depth += 1
        @record[:status] = 'run'
        @record[:total_steps] += type?(seqary, Array).size
        mstat[:result] = 'busy'
        seqary.each { |e| break(true) unless do_step(e, mstat) }
      rescue Interlock
        false
      rescue Interrupt
        mstat[:result] = 'interrupted'
        raise Interrupt
      ensure
        mstat[:result] = 'complete' if mstat[:result] == 'busy'
        @depth -= 1
      end

      # Return false if sequence is broken
      def do_step(e, mstat)
        step = @record.add_step(e, @depth)
        begin
          step.show_title
          return true if method('_' + e[:type]).call(e, step, mstat)
        rescue Retry
          retry
        end
      end

      def upd_sites
        @cfg[:sites].map do |site|
          { site: site, type: 'upd' }
        end
      end

      # Print section
      def _show(str = nil)
        return unless Msg.fg?
        if defined? yield
          puts indent(@depth) + yield.to_s
        else
          print str
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      GetOpts.new('[proj] [cmd] (par)', 'ecn') do |opt|
        cfg = Config.new(option: opt)
        wl = Wat::List.new(cfg) # Take App List
        cfg[:dev_list] = wl
        dbi = Db.new.get
        mobj = Cmd::Remote::Index.new(cfg, dbi.pick([:sites]))
        mobj.add_rem.add_ext(Ext)
        ent = mobj.set_cmd(ARGV)
        seq = Seq.new(ent)
        seq.macro
      end
    end
  end
end
