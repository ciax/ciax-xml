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

        # @sub_stat[:data](picked) = self[:crnt](picked) > self[:last]
        # upd() => self[:last]<-self[:crnt]
        #       => self[:crnt]<-@sub_stat.data(picked)
        #       => check(self[:crnt] <> self[:last]?)
        # Stat no changed -> clear exec, no eval
        def ext_conv
          return self unless @wdb
          @interval = @wdb[:interval].to_f if @wdb.key?(:interval)
          @cond = Condition.new(@wdb[:index] || {}, @sub_stat, self)
          @cmt_procs.append(self, :conv, 1) { conv }
          ___init_auto(@wdb[:regular]) if @wdb.key?(:regular)
          self
        end

        def conv
          return self unless @wdb
          if @sub_stat[:time] > @last_updated
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
        def ___init_auto(reg)
          per = reg[:period].to_i
          @periodm = per * 1000 if per > 0
          @regexe = reg[:exec] || [['upd']]
          verbose do
            cfmt('Initiate Auto Update: Period = %d sec, Command = %s',
                 per / 1000, @regexe)
          end
        end
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      Opt::Get.new('< status_file', options: 't') do |opt, args|
        stat = App::Status.new(args).ext_local.ext_file
        event = Event.new(stat[:id], stat).ext_local.ext_conv
        if (t = opt[:t])
          stat.str_update(t)
        end
        puts event.conv
      end
    end
  end
end
