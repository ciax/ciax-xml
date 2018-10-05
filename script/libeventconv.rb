#!/usr/bin/ruby
require 'libevent'
require 'librerange'
require 'libwatcond'

module CIAX
  # Watch Layer
  module Wat
    # Add extend method in Event
    class Event
      def ext_local_conv(stat, sv_stat = nil)
        extend(Conv).ext_local_conv(stat, sv_stat)
      end
      # Watch Response Module
      module Conv
        def self.extended(obj)
          Msg.type?(obj, Event)
        end

        # @stat[:data](picked) = self[:crnt](picked) > self[:last]
        # upd() => self[:last]<-self[:crnt]
        #       => self[:crnt]<-@stat.data(picked)
        #       => check(self[:crnt] <> self[:last]?)
        # Stat no changed -> clear exec, no eval
        def ext_local_conv(stat, sv_stat = nil)
          @stat = type?(stat, App::Status)
          # No need @sv_stat.upd at reading
          @sv_stat = type?(sv_stat || Prompt.new('site', self[:id]), Prompt)
          wdb = @dbi[:watch] || {}
          @interval = wdb[:interval].to_f if wdb.key?(:interval)
          @cond = Condition.new(wdb[:index] || {}, stat, self)
          ___init_cmt_procs
          ___init_auto(wdb)
        end

        def queue(src, pri, batch = [])
          @last_updated = self[:time]
          batch.each do |args|
            self[:exec] << [src, pri, args]
          end
          self
        end

        def auto_exec
          return self unless update?
          # Do it when no other command in the queue, and not in motion
          return self unless self[:exec].empty? && self[:active].empty?
          verbose { format('Auto Update(%s, %s)', self[:time], @regexe) }
          begin
            queue('auto', 3, @regexe)
          rescue
            errmsg
          end
          self
        end

        private

        def ___init_cmt_procs
          init_time2cmt(@stat)
          @stat.cmt_procs << proc do
            verbose { 'Propagate Status#cmt -> Event#cmt' }
            next unless @stat[:time] > @last_updated
            @last_updated = self[:time]
            @cond.upd_cond
            ___upd_event
            cmt
          end
        end

        # Initiate for Auto Update
        def ___init_auto(wdb)
          reg = wdb[:regular] || {}
          per = reg[:period].to_i
          @periodm = per * 1000 if per > 0
          @regexe = reg[:exec] || [['upd']]
          verbose do
            format('Initiate Auto Update: Period = %d sec, Command = %s)',
                   @periodm / 1000, @regexe)
          end
          self
        end

        # self[:active] : Array of event ids which meet criteria
        # self[:exec] : Command queue which contains commands issued as event
        # self[:block] : Array of commands (units) which are blocked during busy
        # self[:int] : List of interrupt commands which is effectie during busy
        # @sv_stat[:event] is internal var (moving)

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

        def ___upd_event
          if @sv_stat.up?(:event)
            ___event_off
          elsif active?
            ___event_on
          end
          self
        end

        def ___event_on
          at = self[:act_time]
          at[0] = at[1] = now_msec
          @sv_stat.up(:event)
          @on_act_procs.each { |p| p.call(self) }
        end

        def ___event_off
          self[:act_time][1] = now_msec
          return if active?
          @sv_stat.dw(:event)
          @on_deact_procs.each { |p| p.call(self) }
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      odb = { t: 'test conditions[key=val,..]' }
      GetOpts.new('< status_file', odb) do |opt, args|
        stat = App::Status.new(args.shift)
        event = Event.new(stat[:id]).ext_local_conv(stat)
        if (t = opt[:t])
          stat.str_update(t)
        end
        puts event.upd
      end
    end
  end
end
