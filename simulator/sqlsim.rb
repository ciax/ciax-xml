#!/usr/bin/ruby
require 'libsqlsim'
# Device simulator by SqLog
module CIAX
  # Logging by Sql
  module SqLog
    Msg.usage('[id] (ver)') if ARGV.size < 1
    id = ARGV.shift
    ver = ARGV.shift
    ARGV.clear

    logv = Simulator.new(id)
    begin
      while base64 = logv.input
        if str = logv.find_next(base64)
          STDOUT.syswrite(str.unpack('m').first)
        end
      end
    rescue EOFError
    end
  end
end
