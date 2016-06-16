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
      @logfile = vardir('log') + _file_base + "_#{Time.now.year}.log"
      @th_log = _log_thread(id)
      @cmt_procs << proc { @th_log[:queue].push(JSON.dump(self)) }
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
      verbose { "Initiate File Log Server [#{id}/Ver.#{self[:ver]}]" }
      Threadx::Que.new('Logging', @type, @id) { |que| _log_save(que) }
    end

    def _log_save(que)
      str = que.pop
      open(@logfile, 'a') { |f| f.puts str }
      verbose { "Appended #{str.size} byte" }
    end
  end
end
