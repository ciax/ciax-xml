#!/usr/bin/env ruby
require 'libwatstat'
require 'librerange'
require 'libwatcond'

module CIAX
  # Watch Layer
  module Wat
    # Add extend method in Event
    class Event
      # Local mode
      module Local
        include Varx::Local
        def ext_conv
          extend(Conv).ext_conv
        end
      end
      # Watch Response Module
      module Conv
        def self.extended(obj)
          Msg.type?(obj, Event)
        end

        # @status[:data](picked) = self[:crnt](picked) > self[:last]
        # upd() => self[:last]<-self[:crnt]
        #       => self[:crnt]<-@status.data(picked)
        #       => check(self[:crnt] <> self[:last]?)
        # Stat no changed -> clear exec, no eval
        def ext_conv
          wdb = @dbi[:watch] || {}
          @interval = wdb[:interval].to_f if wdb.key?(:interval)
          @cond = Condition.new(wdb[:index] || {}, @status, self)
          @cmt_procs.append(self, :conv, 1) { conv }
          ___init_auto(wdb)
        end

        def conv
          if @status[:time] > @last_updated
            @last_updated = self[:time]
            @cond.upd_cond
            verbose { _conv_text('Symbol -> Event', @id, time_id) }
          end
          self
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
          verbose { cfmt('Auto Update(%s, %s)', time, @regexe) }
          begin
            queue('auto', 3, @regexe)
          rescue
            errmsg
          end
          self
        end

        private

        # Initiate for Auto Update
        def ___init_auto(wdb)
          reg = wdb[:regular] || {}
          per = reg[:period].to_i
          @periodm = per * 1000 if per > 0
          @regexe = reg[:exec] || [['upd']]
          verbose do
            cfmt('Initiate Auto Update: Period = %d sec, Command = %s',
                 per / 1000, @regexe)
          end
          self
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      odb = { t: 'test conditions[key=val,..]' }
      Opt::Get.new('< status_file', odb) do |opt, args|
        stat = App::Status.new(args).ext_local
        event = Event.new(stat[:id]).ext_local.ext_conv
        if (t = opt[:t])
          stat.str_update(t)
        end
        puts event.conv
      end
    end
  end
end
