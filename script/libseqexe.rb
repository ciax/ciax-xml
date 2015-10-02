#!/usr/bin/ruby
require 'libmcrcmd'
require 'librecord'
require 'libwatexe'

module CIAX
  # Modes             | Actual Status? | Force Entering | Query? | Moving | Retry Interval | Record?
  # TEST(default):    | NO  | YES | YES | NO  | 0 | NO
  # NONSTOP TEST(-n): | NO  | YES | NO  | NO  | 0 | NO
  # CHECK(-e):        | YES | YES | YES | NO  | 0 | YES
  # DRYRUN(-ne):      | YES | YES | NO  | NO  | 0 | YES
  # INTERACTIVE(-em): | YES | NO  | YES | YES | 1 | YES
  # NONSTOP(-nem):    | YES | NO  | NO  | YES | 1 | YES

  #MOTION:  TEST <-> REAL (m)
  #QUERY :  INTERACTIVE <-> NONSTOP(n)

  #TEST: query(exec,error,enter), interval=0
  #REAL: query(exec,error), interval=1
  module Mcr
    # Sequencer Layer
    module Seq
      class Exe < Exe
        #required cfg keys: app,db,body,stat,(:submcr_proc)
        attr_reader :cfg, :record, :que_cmd, :que_res, :post_stat_procs, :pre_mcr_procs, :post_mcr_procs, :th_mcr
        #cfg[:submcr_proc] for executing asynchronous submacro, which must returns hash with ['id']
        #ent should have [:sequence]'[:dev_list],[:submcr_proc]
        def initialize(ment, pid = '0')
          super(type?(ment, Entity).id)
          @mcfg = ment
          @sequence = ment.sequence
          type?(@mcfg[:dev_list], CIAX::List)
          @record = Record.new.ext_save.ext_load.mklink # Make latest link
          @record['pid'] = pid
          @submcr_proc = @mcfg[:submcr_proc] || proc{|args|
            show { "Sub Macro #{args} issued\n" }
            { 'id' => 'dmy' }
          }
          @post_stat_procs = [proc { verbose { 'Processing PostStatProcs' } }] # execute on stat changes
          @pre_mcr_procs = [proc { verbose { 'Processing PreMcrProcs' } }]
          @post_mcr_procs = [proc { verbose { 'Processing PostMcrProcs' } }]
          @th_mcr = Thread.current
          @que_cmd = Queue.new
          @que_res = Queue.new
          update({ 'id' => @record['id'], 'cid' => @mcfg[:cid], 'pid' => pid, 'step' => 0, 'total_steps' => @sequence.size, 'stat' => 'ready' })
          @running = []
          @depth = 0
          # For Thread mode
          @cobj.add_rem.add_hid
          int = @cobj.rem.add_int(Int)
          self['option'] = int.valid_keys.clear
          int.def_proc { |ent| reply(ent.id) }
          int.add_item('start', 'Sequece Start').def_proc{
            fork
            'ACCEPT'
          }
        end

        def fork
          @th_mcr = Threadx.new("Macro(#@id)", 10) { macro }
          @cobj.get('interrupt').def_proc{
            @th_mcr.raise(Interrupt)
            'INTERRUPT'
          }
          self
        end

        def to_v
          msg = @record.to_v
          msg << "  [#{self['step']}/#{self['total_steps']}]"
          msg << "(#{self['stat']})"
          msg << optlist(self['option'])
        end

        def ext_shell
          super
          @prompt_proc = proc{
            "(#{self['stat']})" + optlist(self['option'])
          }
          @cfg[:output] = @record
          @cobj.loc.add_view
          self
        end

        def macro
          @record.start(@mcfg)
          show { @record }
          sub_macro(@sequence, @record)
        rescue Interrupt
          msg("\nInterrupt Issued to running devices #{@running}", 3)
          @running.each{|site|
            @mcfg[:dev_list].get(site).exe(['interrupt'], 'user')
          }
        ensure
          @running.clear
          self['option'].clear
          res = @record.finish
          show { "#{res}" }
          set_stat(res)
          @post_mcr_procs.each { |p| p.call(self) }
        end

        private
        # macro returns result (true/false)
        def sub_macro(sequence, mstat)
          @depth += 1
          set_stat('run')
          result = 'complete'
          sequence.each{|e1|
            self['step'] += 1
            begin
              @step = @record.add_step(e1, @depth)
              case e1['type']
              when 'mesg'
                @step.ok?
                query(['ok'])
              when 'goal'
                if @step.skip? && query(['skip', 'force'])
                  result = 'skipped'
                  break true
                end
              when 'check'
                if @step.fail? && query(['drop', 'force', 'retry'])
                  result = 'error'
                  break
                end
              when 'wait'
                if @step.timeout? { show('.') } && query(['drop', 'force', 'retry'])
                  result = 'timeout'
                  break
                end
              when 'exec'
                if @step.exec? && query(['exec', 'pass'])
                  @running << e1['site']
                  @mcfg[:dev_list].get(e1['site']).exe(e1['args'], 'macro')
                end
              when 'mcr'
                if @step.async?
                  if @submcr_proc.is_a?(Proc)
                    @step['id'] = @submcr_proc.call(e1['args'], @record['id'])['id']
                  end
                else
                  res = sub_macro(@mcfg.ancestor(2).set_cmd(e1['args']).sequence, @step)
                  result = @step['result']
                  break unless res
                end
              end
            rescue Retry
              retry
            end
          }
        rescue Interrupt
          result = 'interrupted'
          raise Interrupt
        ensure
          mstat['result'] = result
          @depth -= 1
        end

        # Communicate with forked macro
        def reply(ans)
          if self['stat'] == 'query'
            @que_cmd << ans
            @que_res.pop
          else
            'IGNORE'
          end
        end

        def set_stat(str)
          self['stat'] = str
        ensure
          @post_stat_procs.each { |p| p.call(self) }
        end

        def query(cmds)
          return true if $opt['n']
          self['option'].replace(cmds)
          set_stat 'query'
          res = input(cmds)
          self['option'].clear
          set_stat 'run'
          @step['action'] = res
          case res
          when 'retry'
            raise(Retry)
          when 'interrupt'
            raise(Interrupt)
          when 'force', 'pass'
            false
          else
            true
          end
        end

        def input(cmds)
          Readline.completion_proc = proc { |word| cmds.grep(/^#{word}/) } if Msg.fg?
          loop{
            if Msg.fg?
              prom = @step.body(optlist(self['option']))
              line = Readline.readline(prom, true)
              break 'interrupt' unless line
              id = line.rstrip
            else
              id = @que_cmd.pop.split(/[ :]/).first
            end
            if cmds.include?(id)
              @que_res << 'ACCEPT'
              break id
            elsif !id
              @que_res << ''
            else
              @que_res << 'INVALID'
            end
          }
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

      if __FILE__ == $0
        GetOpts.new('icemntr')
        cfg = Config.new
        al = Wat::List.new(cfg).sub_list #Take App List
        cfg[:dev_list] = al
        mobj = Remote::Index.new(cfg, { :dbi => Db.new.get(PROJ) })
        mobj.add_rem.add_ext(Ext)
        begin
          ent = mobj.set_cmd(ARGV)
          seq = Exe.new(ent)
          if $opt['i']
            seq.macro
          else
            seq.ext_shell.shell
          end
        rescue InvalidCMD
          $opt.usage('[mcr] [cmd] (par)')
        end
      end
    end
  end
end
