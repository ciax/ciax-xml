#!/usr/bin/ruby
require 'libsqlog'
module CIAX
  # Variable status data
  class Varx
    def ext_local_log
      extend(JsLog).ext_local_log
    end

    # Add Data Logging feature
    module JsLog
      def self.extended(obj)
        Msg.type?(obj, Varx)
      end

      def ext_local_log # logging with flatten
        id = self[:id]
        @logfile = vardir('log') + _file_base + "_#{Time.now.year}.log"
        @que_log = _log_thread_(id)
        @cmt_procs << proc { @que_log.push(JSON.dump(self)) }
        self
      end

      # Read JSON Logfile
      def self.read(str)
        h = Msg.j2h(str)
        give_up('Logline:Line is not rcv') unless /rcv/ =~ h[:dir]
        if h[:base64]
          def h.binary
            self[:base64].unpack('m').first
          end
        end
        h
      end

      def ext_local_sqlog
        # Logging if version number exists
        id = self[:id]
        # init_table includes initiate/auto save
        (SqLog.list[id] ||= SqLog::Save.new(id)).init_table(@layer, self)
        self
      end

      private

      def _log_thread_(id)
        verbose { "Initiate File Log Server [#{id}/Ver.#{self[:ver]}]" }
        Threadx::QueLoop.new('Logging', @layer, @id, @type) do |que|
          str = que.pop
          open(@logfile, 'a') { |f| f.puts str }
          verbose { "Appended #{str.size} byte" }
        end
      end
    end
  end
end
