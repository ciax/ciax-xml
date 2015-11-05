#!/usr/bin/ruby
require 'libsqlog'
module CIAX
  # Add Data Logging feature
  module JsLog
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    def ext_log # logging with flatten
      id = self['id']
      ver = self['ver']
      verbose { "Log Initialize [#{id}/Ver.#{ver}]" }
      @queue = Queue.new
      @post_upd_procs << proc { @queue.push(to_j) }
      logfile = vardir('log') + file_base + "_#{Time.now.year}.log"
      ThreadLoop.new("Logging(#{@type}:#{id})", 11) do
        logary = []
        loop do
          logary << @queue.pop
          break if @queue.empty?
        end
        open(logfile, 'a') do|f|
          logary.each do|str|
            f.puts str
            verbose { "Appended #{str.size} byte" }
          end
        end
      end
      self
    end

    # Load JSON Logfile
    def self.load(str)
      h = JSON.load(str)
      give_up('Logline:Line is not rcv') unless /rcv/ =~ h['dir']
      if h['base64']
        def h.binary
          self['base64'].unpack('m').first
        end
      end
      h
    end
  end
end
