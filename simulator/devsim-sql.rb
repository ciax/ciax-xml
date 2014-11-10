#!/usr/bin/ruby
require "libsqlog"
# Device simulator by SqLog

module CIAX
  module SqLog
    Msg.usage("[id] (ver)") if ARGV.size < 1
    id=ARGV.shift
    ver=ARGV.shift
    ARGV.clear

    logv=LogRing.new(id)
    begin
      while base64=logv.input
        if str=logv.find_next(base64)
          STDOUT.syswrite(str.unpack("m").first)
        end
      end
    rescue EOFError
    end
  end
end

