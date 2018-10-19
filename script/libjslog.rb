#!/usr/bin/ruby
require 'libthreadx'
module CIAX
  # Variable status data
  class Varx
    # Add Data Logging feature
    module JsLog
      def self.extended(obj)
        Msg.type?(obj, Varx)
      end

      def ext_local_log # logging with flatten
        @logfile = vardir('log') + base_name + "_#{Time.now.year}.log"
        @que_log = ___log_thread
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
        require 'libsqlog'
        # Logging if version number exists
        # init_table includes initiate/auto save
        SqLog.new(@id).init_table(@layer, self)
        self
      end

      private

      def ___log_thread
        verbose { "Initiate File Log Server [#{@id}/Ver.#{self[:ver]}]" }
        Threadx::QueLoop.new('Logging', @layer, @id, @type) do |que|
          str = que.pop
          open(@logfile, 'a') { |f| f.puts str }
          verbose { "Appended #{str.size} byte" }
        end
      end
    end
  end
end
