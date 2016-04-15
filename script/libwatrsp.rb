#!/usr/bin/ruby
require 'libevent'
require 'librerange'
require 'libwatcond'

module CIAX
  # Watch Layer
  module Wat
    # Watch Response Module
    module Rsp
      def self.extended(obj)
        Msg.type?(obj, Event)
      end

      # @stat[:data](picked) = self[:crnt](picked) > self[:last]
      # upd() => self[:last]<-self[:crnt]
      #       => self[:crnt]<-@stat.data(picked)
      #       => check(self[:crnt] <> self[:last]?)
      # Stat no changed -> clear exec, no eval
      def ext_rsp(stat, sv_stat = nil)
        @stat = type?(stat, App::Status)
        @sv_stat = type?(sv_stat || Prompt.new('site', self[:id]), Prompt)
        wdb = @dbi[:watch] || {}
        @interval = wdb[:interval].to_f if wdb.key?(:interval)
        @cond = Condition.new(wdb[:index] || {}, stat, self)
        _init_proc
        _init_auto(wdb)
      end

      def queue(src, pri, batch = [])
        @last_updated = self[:time]
        batch.each do|args|
          self[:exec] << [src, pri, args]
        end
        self
      end

      def auto_exec
        return self unless self[:exec].empty?
        verbose { format('Auto Update(%s, %s)', self[:time], @regexe) }
        begin
          queue('auto', 3, @regexe)
        rescue InvalidARGS
          errmsg
        rescue
          warning $ERROR_INFO
        end
        self
      end

      private

      def time_upd
        super(@stat[:time])
      end

      def _init_proc
        @stat.cmt_procs << proc do
          verbose { 'Propagate Status#upd -> Event#upd' }
          upd
        end
      end

      # Initiate for Auto Update
      def _init_auto(wdb)
        reg = wdb[:regular] || {}
        per = reg[:period].to_i
        @period = per > 1 ? per : 300
        @regexe = reg[:exec] || [['upd']]
        verbose do
          format('Initiate Auto Update: Period = %s sec, Command = %s)',
                 @period, @regexe)
        end
        self
      end

      # self[:active] : Array of event ids which meet criteria
      # self[:exec] : Command queue which contains commands issued as event
      # self[:block] : Array of commands (units) which are blocked during busy
      # self[:int] : List of interrupt commands which is effectie during busy
      def upd_core
        time_upd(@stat[:time])
        return self unless @stat[:time] > @last_updated
        @last_updated = self[:time]
        @cond.upd
        upd_event
        self
      end

      # @sv_stat[:event] is internal var

      ## Timing chart in active mode
      # isu   :__--__--__--==__--___
      # actv  :___--------__----____
      # event :_____---------------__

      ## Trigger Table
      # isu | actv|event| action
      #  o  |  o  |  o  |  -
      #  o  |  x  |  o  |  -
      #  o  |  o  |  x  |  up
      #  o  |  x  |  x  |  -
      #  x  |  o  |  o  |  -
      #  x  |  x  |  o  | down
      #  x  |  o  |  x  |  up
      #  x  |  x  |  x  |  -

      def upd_event
        if @sv_stat.up?(:event)
          _event_off unless active?
        elsif active?
          _event_on
        end
        self
      end

      def _event_on
        @sv_stat.up(:event)
        self[:act_time][1] = @last_updated
        @on_act_procs.each { |p| p.call(self) }
      end

      def _event_off
        return if @sv_stat.up?(:busy)
        @sv_stat.dw(:event)
        @on_deact_procs.each { |p| p.call(self) }
      end
    end

    # Add extend method in Event
    class Event
      def ext_rsp(stat, sv_stat = nil)
        extend(Wat::Rsp).ext_rsp(stat, sv_stat)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      odb = { t: 'test conditions[key=val,..]' }
      GetOpts.new('[site] | < status_file', 't:', odb) do |opt|
        stat = App::Status.new
        stat.ext_file.load if STDIN.tty?
        event = Event.new(stat[:id]).ext_rsp(stat)
        if (t = opt[:t])
          stat.str_update(t)
        end
        puts event.upd
      end
    end
  end
end
