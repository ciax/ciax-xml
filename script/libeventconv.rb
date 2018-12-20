#!/usr/bin/ruby
require 'libevent'
require 'librerange'
require 'libwatcond'

module CIAX
  # Watch Layer
  module Wat
    # Add extend method in Event
    class Event
      def ext_local_conv(stat)
        extend(Conv).ext_local_conv(stat)
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
        def ext_local_conv(stat)
          @stat = type?(stat, App::Status)
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
          @cmt_procs << proc do
            next unless @stat[:time] > @last_updated
            @last_updated = self[:time]
            @cond.upd_cond
          end
          cmt_propagate(@stat)
        end

        # Initiate for Auto Update
        def ___init_auto(wdb)
          reg = wdb[:regular] || {}
          per = reg[:period].to_i
          @periodm = per * 1000 if per > 0
          @regexe = reg[:exec] || [['upd']]
          verbose do
            format('Initiate Auto Update: Period = %d sec, Command = %s',
                   @periodm / 1000, @regexe)
          end
          self
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
