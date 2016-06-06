#!/usr/bin/ruby
require 'libsqlog'
module CIAX
  # Add Data Logging feature
  module JsLog
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    def ext_local_log # logging with flatten
      id = self[:id]
      @queue = Queue.new
      @cmt_procs << proc { @queue.push(JSON.dump(self)) }
      @logfile = vardir('log') + _file_base + "_#{Time.now.year}.log"
      _log_thread(id)
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
      # add_table includes initiate/auto save
      (SqLog::LIST[id] ||= SqLog::Save.new(id)).add_table(self)
      self
    end

    private

    def _log_thread(id)
      Threadx.new("Logging(#{@type})", @id) do
        verbose { "Initiate File Log [#{id}/Ver.#{self[:ver]}]" }
        loop { _log_save }
      end
    end

    def _log_save
      str = @queue.pop
      open(@logfile, 'a') { |f| f.puts str }
      verbose { "Appended #{str.size} byte" }
    end
  end
end
