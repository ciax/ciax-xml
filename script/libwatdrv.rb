#!/usr/bin/env ruby
module CIAX
  # Watch Layer
  module Wat
    class Exe
      # Event Driven
      module Driver
        def self.extended(obj)
          Msg.type?(obj, Exe)
        end

        def ext_local_driver
          @stat.ext_local_conv
          # @stat[:int] is overwritten by initial loading
          @sub.batch_interrupt = @stat.get(:int)
          ___init_cmt_procs
          ___init_exe_processor
          @stat.ext_local_log if @opt.drv?
          self
        end

        private

        def ___init_cmt_procs
          @stat.cmt_procs.append do |s|
            ___flush_blocklist(s)
            ___exec_by_event(s)
            ___event_flag(s)
          end
        end

        def ___init_exe_processor
          @th_auto = ___init_auto_thread unless @cfg[:cmd_line_mode]
          @sub.post_exe_procs << proc do
            @sv_stat.set_flg(:auto, @th_auto && @th_auto.alive?)
          end
        end

        def ___init_auto_thread
          Threadx::Loop.new('Auto', 'wat', @id) do
            @stat.auto_exec unless @sv_stat.up?(:comerr)
            sleep 10
          end
        end

        def ___flush_blocklist(ev)
          verbose { 'Propagate Event#cmt -> Watch#(set blocking command)' }
          block = ev.get(:block).map { |id, par| par ? nil : id }.compact
          @cobj.rem.ext.valid_sub(block)
        end

        def ___exec_by_event(ev)
          ev.get(:exec).each do |src, pri, args|
            verbose { _exe_text('Executing by Event', args.inspect, src, pri) }
            @sub.exe(args, src, pri)
            sleep ev.interval
          end.clear
        end

        # @stat[:active] : Array of event ids which meet criteria
        # @stat[:exec] : Cmd queue which contains cmds issued as event
        # @stat[:block] : Array of cmds (units) which are blocked during busy
        # @stat[:int] : List of interrupt cmds which is effectie during busy
        # @sv_stat[:event] is internal var (actuator moving)

        ## Timing chart in active mode
        # busy  :__--__--__--==__--___
        # activ :___--------__----____
        # event :_____---------------__

        ## Trigger Table
        # busy| actv|event| action to event
        #  o  |  o  |  o  |  -
        #  o  |  x  |  o  |  -
        #  o  |  o  |  x  |  up
        #  o  |  x  |  x  |  -
        #  x  |  o  |  o  |  -
        #  x  |  x  |  o  | down
        #  x  |  o  |  x  |  up
        #  x  |  x  |  x  |  -

        def ___event_flag(s)
          if @sv_stat.up?(:event)
            s.act_upd
            @sv_stat.dw(:event) unless s.active?
          elsif s.active?
            s.act_start
            @sv_stat.up(:event)
          end
        end
      end
    end
  end
end
