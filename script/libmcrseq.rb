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
        type?(@cfg[:dev_list], CIAX::List)
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
        @qry = Query.new(@record, valid_keys)
      end

      # For prompt '(stat) [option]'
      def to_v
        @qry.to_v
      end

      def reply(str)
        @qry.reply(str)
      end

      def macro
        Thread.current[:id] = @id
        Thread.current[:obj] = self
        show(@record.start)
        sub_macro(@cfg, @record)
      rescue Interrupt
        msg("\nInterrupt Issued to running devices #{@sv_stat[:run]}", 3)
        @sv_stat.get(:run).each do|site|
          @cfg[:dev_list].get(site).exe(['interrupt'], 'user')
        end
      ensure
        @sv_stat.flush(:run)
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
        mstat[:result] = 'busy'
        begin
          ment[:sequence].each do|e|
            step = @record.add_step(e, @depth)
            begin
              break true if method(e[:type]).call(e, step, mstat)
            rescue Retry
              retry
            end
          end
        rescue Interlock
          false
        end
      rescue Interrupt
        mstat[:result] = 'interrupted'
        raise Interrupt
      ensure
        mstat[:result] = 'complete' if mstat[:result] == 'busy'
        @depth -= 1
      end

      def mesg(_e, step, _mstat)
        step.ok?
        @qry.query(['ok'], step)
        false
      end

      def goal(_e, step, mstat)
        return unless step.skip? && @qry.query(%w(skip force), step)
        mstat[:result] = 'skipped'
      end

      def check(_e, step, mstat)
        return unless step.fail? && @qry.query(%w(drop force retry), step)
        mstat[:result] = 'error'
        fail Interlock
      end

      def wait(_e, step, mstat)
        return unless step.timeout? && @qry.query(%w(drop force retry), step)
        mstat[:result] = 'timeout'
        fail Interlock
      end

      def exec(e, step, _mstat)
        if step.exec? && @qry.query(%w(exec pass), step)
          @sv_stat.push(:run, e[:site]).uniq!
          @cfg[:dev_list].get(e[:site]).exe(e[:args], 'macro')
        end
        false
      end

      def mcr(e, step, mstat)
        seq = @cfg.ancestor(2).set_cmd(e[:args])
        if step.async? && @submcr_proc.is_a?(Proc)
          step[:id] = @submcr_proc.call(seq, @id).id
        else
          res = mcr_fg(e, seq, step)
          mstat[:result] = step[:result]
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
      OPT.parse('ecm')
      cfg = Config.new
      al = Wat::List.new(cfg).sub_list # Take App List
      cfg[:dev_list] = al
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
