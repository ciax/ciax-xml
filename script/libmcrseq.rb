#!/usr/bin/ruby
require 'libmcrcmd'
require 'libmcrrsp'
require 'libwatexe'
require 'libmcrqry'

module CIAX
  # Macro Layer
  module Mcr
    # Sequencer
    class Seq
      include Msg
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
        show(@record.start)
        init_sites
        sub_macro(@cfg, @record)
      rescue Interrupt
        msg("\nInterrupt Issued to running devices #{@sv_stat.get(:run)}", 3)
        @sv_stat.get(:run).each do|site|
          @cfg[:dev_list].get(site).exe(['interrupt'], 'user')
        end
      ensure
        show(@record.finish)
      end

      def fork
        Threadx.new("Macro(#{@id})", 10) { macro }
      end

      private

      # macro returns result (true/false)
      def sub_macro(ment, mstat)
        @depth += 1
        @record[:status] = 'run'
        @record[:total_steps] += ment[:sequence].size
        mstat[:result] = 'busy'
        ment[:sequence].each { |e| break(true) if do_step(e, mstat) }
      rescue Interlock
        false
      rescue Interrupt
        mstat[:result] = 'interrupted'
        raise Interrupt
      ensure
        mstat[:result] = 'complete' if mstat[:result] == 'busy'
        @depth -= 1
      end

      def do_step(e, mstat)
        step = @record.add_step(e, @depth)
        begin
          return true if method(e[:type]).call(e, step, mstat)
        rescue Retry
          retry
        end
      end

      def init_sites
        @cfg[:dbi][:sites].each do |site|
          @cfg[:dev_list].get(site).exe(['upd'], 'macro').join('macro')
        end
      end

      def mesg(_e, step, _mstat)
        step.ok?
        @qry.query(['ok'], step)
        false
      end

      def goal(_e, step, mstat)
        return unless step.skip?
        return if OPT.test? && !@qry.query(%w(skip force), step)
        mstat[:result] = 'skipped'
      end

      def check(_e, step, mstat)
        return unless step.fail? &&
                      @qry.query(%w(drop force retry), step)
        mstat[:result] = 'error'
        fail Interlock
      end

      alias_method :verify, :check

      def wait(e, step, mstat)
        if (s = e[:sleep])
          step.sleeping(s)
          return
        end
        return unless step.timeout? &&
                      @qry.query(%w(drop force retry), step)
        mstat[:result] = 'timeout'
        fail Interlock
      end

      def exec(e, step, _mstat)
        if step.exec? && @qry.query(%w(exec pass), step)
          @cfg[:dev_list].get(e[:site]).exe(e[:args], 'macro').join('macro')
        end
        @sv_stat.push(:run, e[:site])
        false
      end

      def cfg(e, step, _mstat)
        step.ok?
        @cfg[:dev_list].get(e[:site]).exe(e[:args], 'macro').join('macro')
        false
      end

      def upd(e, step, _mstat)
        step.ok?
        @cfg[:dev_list].get(e[:site]).exe(['upd'], 'macro').join('macro')
        false
      end

      def mcr(e, step, _mstat)
        seq = @cfg.ancestor(2).set_cmd(e[:args])
        if step.async? && @submcr_proc.is_a?(Proc)
          step[:id] = @submcr_proc.call(seq, @id).id
        else
          res = mcr_fg(e, seq, step)
          fail Interlock unless res
        end
        false
      end

      def mcr_fg(e, seq, step)
        (e[:retry] || 1).to_i.times do
          res = sub_macro(seq, step)
          return res if res
          step[:action] = 'retry'
        end
        nil
      end

      # Print section
      def show(str = nil)
        return unless Msg.fg?
        if defined? yield
          puts indent(@depth) + yield.to_s
        else
          print str
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      OPT.parse('ecmn')
      cfg = Config.new
      wl = Wat::List.new(cfg) # Take App List
      cfg[:dev_list] = wl
      begin
        mobj = Remote::Index.new(cfg, dbi: Db.new.get)
        mobj.add_rem.add_ext(Ext)
        ent = mobj.set_cmd(ARGV)
        seq = Seq.new(ent)
        seq.macro
      rescue InvalidCMD
        OPT.usage('[cmd] (par)')
      rescue InvalidID
        OPT.usage('[proj] [cmd] (par)')
      end
    end
  end
end
