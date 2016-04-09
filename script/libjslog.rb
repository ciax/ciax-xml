#!/usr/bin/ruby
require 'libsqlog'
module CIAX
  # Add Data Logging feature
  module JsLog
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    def ext_log # logging with flatten
      id = self[:id]
      @queue = Queue.new
      @post_upd_procs << proc { @queue.push(JSON.dump(self)) }
      Threadx.new("Logging(#{@type}:#{id})", 11) do
        verbose { "Log Initialize [#{id}/Ver.#{self[:ver]}]" }
        _log_loop
      end
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

    def ext_sqlog
      # Logging if version number exists
      SqLog::Save.new(self[:id], @type).add_table(self)
      self
    end

    private

    def _log_loop
      logfile = vardir('log') + _file_base + "_#{Time.now.year}.log"
      loop do
        str = @queue.pop
        open(logfile, 'a') { |f| f.puts str }
        verbose { "Appended #{str.size} byte" }
      end
    end
  end
end
