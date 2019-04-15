#!/usr/bin/env ruby
require 'libthreadx'
module CIAX
  # Add Data Logging feature
  module JsLog
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    # logging with flatten
    def ext_log
      @logfile = vardir('log') + base_name + "_#{Time.now.year}.log"
      @que = ___log_thread.que
      @cmt_procs.append(self, :flog, 2) { save_log }
      self
    end

    def save_log
      @que.push(JSON.dump(self))
    end

    # Read JSON Logfile
    def self.read(str)
      h = Msg.j2h(str)
      give_up('Logline:Line is not rcv') unless /rcv/ =~ h[:dir]
      if h[:base64]
        def h.binary
          dec64(self[:base64])
        end
      end
      h
    end

    def ext_sqlog
      require 'libsqlog'
      # Logging if version number exists
      # init_table includes initiate/auto save
      SqLog.new(@id).init_table(@layer, self)
      self
    end

    private

    def ___log_thread
      verbose { "Initiate File Log Server [#{@id}/Ver.#{self[:data_ver]}]" }
      Threadx::QueLoop.new('Logging', @layer, @id, type: @type) do |que|
        str = que.pop
        open(@logfile, 'a') { |f| f.puts str }
        verbose { "Appended #{str.size} byte" }
      end
    end
  end
end
