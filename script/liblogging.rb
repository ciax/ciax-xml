#!/usr/bin/ruby
require 'libmsg'
require 'json'
require 'libthreadx'

# Capable of wider application than SqLog
module CIAX
  class Logging
    include Msg
    def initialize(type, header)
      @cls_color = 14
      type?(type, String)
      @header = type?(header, Hash)
      id = @header['id']
      ver = @header['ver']
      @loghead = vardir('log') + "#{type}_#{id}"
      verbose { "Initialize (#{id}/Ver.#{ver})" }
      @queue = Queue.new
      ThreadLoop.new("Old Logging(#{type}:#{id})", 11) do
        logary = []
        loop do
          logary << @queue.pop
          break if @queue.empty?
        end
        open(logfile, 'a') do|f|
          logary.each do|str|
            f.puts str
            verbose { "Appended #{str.size} byte\n" + str }
          end
        end
      end
    end

    # Return UnixTime
    def append(data)
      time = @header['time'] = now_msec
      unless ENV.key?('NOLOG')
        str = JSON.dump(@header.merge(data))
        @queue.push str
      end
      time
    end

    # For new format
    def self.set_logline(str)
      h = JSON.load(str)
      give_up('Logline:Line is not rcv') unless /rcv/ =~ h['dir']
      if h['base64']
        def h.binary
          self['base64'].unpack('m').first
        end
      end
      h
    end

    private

    def logfile
      @loghead + "_#{Time.now.year}.log"
    end

    def encode(str)
      # str.dump
      [str].pack('m').split("\n").join('')
    end
  end
end
