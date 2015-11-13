#!/usr/bin/ruby
require 'libmcrcmd'
require 'libmcrrsp'
require 'libwatexe'
require 'libmcrqry'

module CIAX
  module Mcr
    class Seq
      include Msg
      # required cfg keys: app,db,body,stat,(:submcr_proc)
      attr_reader :cfg, :record, :qry ,:id
      # cfg[:submcr_proc] for executing asynchronous submacro,
      #   which must returns hash with ['id']
      # ent should have [:sequence]'[:dev_list],[:submcr_proc]
      def initialize(ment, pid = '0', valid_keys = [])
        @cfg = ment
        type?(@cfg[:dev_list], CIAX::List)
        @record = Record.new.ext_file.auto_save.mklink # Make latest link
        @record['pid'] = pid
        @id = @record['id']
        @submcr_proc = @cfg[:submcr_proc] || proc do|args|
          show { "Sub Macro #{args} issued\n" }
          { 'id' => 'dmy' }
        end
        @running = []
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
        @record.ext_rsp(@cfg)
        show { @record }
        sub_macro(@cfg[:sequence], @record)
      rescue Interrupt
        msg("\nInterrupt Issued to running devices #{@running}", 3)
        @running.each do|site|
          @cfg[:dev_list].get(site).exe(['interrupt'], 'user')
        end
      ensure
        @running.clear
        res = @record.finish
        show { "#{res}" }
      end

      def fork
        Threadx.new("Macro(#{@id})", 10) { macro }
      end

      private

      # macro returns result (true/false)
      def sub_macro(sequence, mstat)
        @depth += 1
        @record['status'] = 'run'
        mstat['result'] = 'complete'
        begin
          sequence.each do|e|
            step = @record.add_step(e, @depth)
            begin
              break true if method(e['type']).call(e,step,mstat)
            rescue Retry
              retry
            end
          end
        rescue Interlock
          false
        end
      rescue Interrupt
        mstat['result'] = 'interrupted'
        raise Interrupt
      ensure
        @depth -= 1
      end

      def mesg(e,step,mstat)
        step.ok?
        @qry.query(['ok'], step)
        false
      end

      def goal(e,step,mstat)
        if step.skip? && @qry.query(%w(skip force), step)
          mstat['result'] = 'skipped'
        end
      end

      def check(e,step,mstat)
        if step.fail? && @qry.query(%w(drop force retry), step)
          mstat['result'] = 'error'
          raise Interlock
        end
      end

      def wait(e,step,mstat)
        if step.timeout? && @qry.query(%w(drop force retry), step)
          mstat['result'] = 'timeout'
          raise Interlock
        end
      end

      def exec(e,step,mstat)
        if step.exec? && @qry.query(%w(exec pass), step)
          @running << e['site']
          @cfg[:dev_list].get(e['site']).exe(e['args'], 'macro')
        end
      end

      def mcr(e,step,mstat)
        if step.async?
          if @submcr_proc.is_a?(Proc)
            step['id'] = @submcr_proc.call(e['args'], @record['id'])['id']
          end
        else
          res = sub_macro(@cfg.ancestor(2).set_cmd(e['args'])[:sequence], step)
          mstat['result'] = step['result']
          raise Interlock unless res
        end
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
