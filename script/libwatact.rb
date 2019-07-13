#!/usr/bin/env ruby
require 'libmsg'

module CIAX
  # Watch Layer
  module Wat
    class Exe
      # Event Action class
      #   Required Vars
      #   1.Event as Trigger (@event)
      #   2.Execution (@eobj)
      #   3.Server Status (@sv_stat)
      class Action
        include Msg
        def initialize(event, sv_stat, eobj)
          @event = type?(event, Event)
          @sv_stat = type?(sv_stat, Prompt)
          @eobj = type?(eobj, Exe)
        end

        def action
          ___flush_blocklist
          ___upd_by_action
          ___exec_by_event
          ___event_flag
          self
        end

        private

        def ___flush_blocklist
          block = @event.get(:block).map { |id, par| par ? nil : id }.compact
          @eobj.cobj.rem.ext.valid_sub(block)
        end

        def ___upd_by_action
          @event[:exec] << ['event', 2, ['upd']] if @sv_stat.up?(:action)
        end

        def ___exec_by_event
          @event.get(:exec).each do |src, pri, args|
            verbose { _exe_text(args.inspect, src, pri) }
            @eobj.exe(args, src, pri)
            sleep @event.interval
          end.clear
        end

        # @event[:active] : Array of event ids which meet criteria
        # @event[:exec] : Cmd queue which contains cmds issued as event
        # @event[:block] : Array of cmds (units) which are blocked during busy
        # @event[:int] : List of interrupt cmds which is effectie during busy
        # @sv_stat[:action] : Flag by command type 'action' (actuator moving)
        # @sv_stat[:event] is internal var (actuator moving)

        ## Timing chart in active mode
        # busy   :__--__--__--==__--___
        # action :___---_______________
        # active :_____------__----____
        # event  :_____-------------___

        ## Trigger Table
        # activ|event| mark| @sv_stat
        #   o  |  o  |  e  | cmt
        #   x  |  o  |  e  | evnet:down
        #   o  |  x  |  s  | event:up
        #   x  |  x  |  -  | cmt

        def ___event_flag
          if @sv_stat.up?(:event)
            @event.mark_end
            @sv_stat.dw(:event, :action) unless @event.active?
          elsif @event.active?
            @event.mark_start
            @sv_stat.up(:event)
          end
        end
      end
    end
  end
end
