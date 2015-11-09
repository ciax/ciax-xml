#!/usr/bin/ruby
require 'libmcrcmd'
require 'libmcrrsp'
require 'libwatexe'
require 'libseqqry'

module CIAX
  # Modes Legend:
  #   AS: Actual Status?
  #   FE: Force Entering
  #   QW: Query? (Interactive?)
  #   MV: Moving
  #   RI: Retry with Interval
  #   RC: Recording?
  # Mode Table
  # Field             | AS  | FE  | QW  | MV  | RI| RC
  # TEST(default):    | NO  | YES | YES | NO  | 0 | NO
  # NONSTOP TEST(-n): | NO  | YES | NO  | NO  | 0 | NO
  # CHECK(-e):        | YES | YES | YES | NO  | 0 | YES
  # DRYRUN(-ne):      | YES | YES | NO  | NO  | 0 | YES
  # INTERACTIVE(-em): | YES | NO  | YES | YES | 1 | YES
  # NONSTOP(-nem):    | YES | NO  | NO  | YES | 1 | YES

  # MOTION:  TEST <-> REAL (m)
  # QUERY :  INTERACTIVE <-> NONSTOP(n)

  # TEST: query(exec,error,enter), interval=0
  # REAL: query(exec,error), interval=1
  module Mcr
    # Sequencer Layer
    module Seq
      class Exe < Exe
        # required cfg keys: app,db,body,stat,(:submcr_proc)
        attr_reader :cfg, :record,
                    :post_stat_procs, :pre_mcr_procs, :post_mcr_procs, :th_mcr
        # cfg[:submcr_proc] for executing asynchronous submacro,
        #   which must returns hash with ['id']
        # ent should have [:sequence]'[:dev_list],[:submcr_proc]
        def initialize(ment, pid = '0')
          super(type?(ment, Entity).id)
          @mcfg = ment
          type?(@mcfg[:dev_list], CIAX::List)
          @record = Record.new.ext_save.ext_load.mklink # Make latest link
          @record['pid'] = pid
          @submcr_proc = @mcfg[:submcr_proc] || proc do|args|
            show { "Sub Macro #{args} issued\n" }
            { 'id' => 'dmy' }
          end
          # execute on stat changes
          @pre_mcr_procs = [proc { verbose { 'Processing PreMcrProcs' } }]
          @post_mcr_procs = [proc { verbose { 'Processing PostMcrProcs' } }]
          @th_mcr = Thread.current
          @running = []
          @depth = 0
          # For Thread mode
          @cobj.add_rem.add_hid
          int = @cobj.rem.add_int(Int)
          @qry = Query.new(@record, int.valid_keys.clear)
          int.def_proc { |ent| @qry.reply(ent.id) }
        end

        def fork
          @th_mcr = Threadx.new("Macro(#{@id})", 10) { macro }
          @cobj.get('interrupt').def_proc do
            @th_mcr.raise(Interrupt)
            'INTERRUPT'
          end
          self
        end

        def to_v
          @record.to_v + @qry.to_v
        end

        def ext_shell
          super
          @prompt_proc = proc { @qry.to_v }
          @cfg[:output] = @record
          @cobj.loc.add_view
          self
        end

        def macro
          @record.ext_rsp(@mcfg)
          show { @record }
          sub_macro(@mcfg[:sequence], @record)
        rescue Interrupt
          msg("\nInterrupt Issued to running devices #{@running}", 3)
          @running.each do|site|
            @mcfg[:dev_list].get(site).exe(['interrupt'], 'user')
          end
        ensure
          @running.clear
          res = @record.finish
          show { "#{res}" }
          @record['status'] = res
          @post_mcr_procs.each { |p| p.call(self) }
        end

        private

        # macro returns result (true/false)
        def sub_macro(sequence, mstat)
          @depth += 1
          @record['status'] = 'run'
          result = 'complete'
          sequence.each do|e1|
            begin
              step = @record.add_step(e1, @depth)
              case e1['type']
              when 'mesg'
                step.ok?
                @qry.query(['ok'], step)
              when 'goal'
                if step.skip? && @qry.query(%w(skip force), step)
                  result = 'skipped'
                  break true
                end
              when 'check'
                if step.fail? && @qry.query(%w(drop force retry), step)
                  result = 'error'
                  break
                end
              when 'wait'
                if step.timeout? { show('.') } && @qry.query(%w(drop force retry), step)
                  result = 'timeout'
                  break
                end
              when 'exec'
                if step.exec? && @qry.query(%w(exec pass), step)
                  @running << e1['site']
                  @mcfg[:dev_list].get(e1['site']).exe(e1['args'], 'macro')
                end
              when 'mcr'
                if step.async?
                  if @submcr_proc.is_a?(Proc)
                    step['id'] = @submcr_proc.call(e1['args'], @record['id'])['id']
                  end
                else
                  res = sub_macro(@mcfg.ancestor(2).set_cmd(e1['args'])[:sequence], step)
                  result = step['result']
                  break unless res
                end
              end
            rescue Retry
              retry
            end
          end
        rescue Interrupt
          result = 'interrupted'
          raise Interrupt
        ensure
          mstat['result'] = result
          @depth -= 1
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
        OPT.parse('icemntr')
        cfg = Config.new
        al = Wat::List.new(cfg).sub_list # Take App List
        cfg[:dev_list] = al
        begin
          mobj = Remote::Index.new(cfg, dbi: Db.new.get)
          mobj.add_rem.add_ext(Ext)
          ent = mobj.set_cmd(ARGV)
          seq = Exe.new(ent)
          if OPT['i']
            seq.macro
          else
            seq.fork.ext_shell.shell
          end
        rescue InvalidCMD
          OPT.usage('[cmd] (par)')
        rescue InvalidID
          OPT.usage('[proj] [cmd] (par)')
        end
      end
    end
  end
end
