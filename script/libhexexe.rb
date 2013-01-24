#!/usr/bin/ruby
# Ascii Pack
require "libmsg"
require "libhexview"

module Hex
  module Sv
    def self.extended(obj)
      Msg.type?(obj,App::Sv)
      self
    end

    def server(ver=nil)
      @output=View.new(self,@stat)
      if ver
        logging=Logging.new('hex',self['id'],ver){
          {'hex' => @output.to_s}
        }
        @log_proc.add{logging.append}
        @buf.flush_proc.add{logging.append}
      end
      super(@adb['port'].to_i+1000)
    end

    private
    def filter_in(line)
      return [] if /^(strobe|stat)/ === line
      line.split(' ')
    end

    def filter_out
      @output.to_s
    end
  end
end

module App
  class Sv
    def ext_hex(ver=nil)
      id=self['id']
      if Hex::View.sdb(id)
        init_ver('Hex',2)
        extend(Hex::Sv).server(ver)
      else
        Msg.alert("Hex/Can't found SDB for #{id}")
      end
      self
    end
  end
end
