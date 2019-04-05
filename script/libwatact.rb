#!/usr/bin/env ruby
require 'libwatdrv'

module CIAX
  # Watch Layer
  module Wat
    class Exe
      # Event Action
      class Action
        include Msg
        def initialize(event, sv_stat, eobj)
          @event = type?(event, Event)
          @sv_stat = type?(sv_stat, Prompt)
          @eobj = type?(eobj, App::Exe)
        end

        def action
          ___flush_blocklist
          ___exec_by_event
          ___event_flag
          self
        end

        private

        def ___flush_blocklist
          block = @event.get(:block).map { |id, par| par ? nil : id }.compact
          @eobj.cobj.rem.ext.valid_sub(block)
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

        def ___event_flag
          if @sv_stat.up?(:event)
            @event.act_upd
            @sv_stat.dw(:event) unless @event.active?
          elsif @event.active?
            @event.act_start
            @sv_stat.up(:event)
          end
        end
      end
    end
  end
end
