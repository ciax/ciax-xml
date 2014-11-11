#!/usr/bin/ruby
# Field Point I/O Simulator
require 'gserver'

class FPIO < GServer
  def initialize(port=10002,*args)
    super(port,*args)
    Thread.abort_on_exception=true
    @input=0
    @output=0
  end

  def serve(io)
    while str=io.gets("\r").chomp
      sleep 0.1
      warn str
      case str
      when /^>02!JCD/
        base="%04X" % @output
      when /^>03!JCE/
        base="%04X" % @input
      when /^>02!L/
        mask=$'[0,4].hex
        data=$'[4,4].hex
        stay=@output & (65535 ^ mask)
        chg=data & mask
        @output=stay+chg
        base=nil
      end
      if base
        chk=0
        base.each_byte{|c| chk += c }
        base="#{base}%02X" % (chk%256)
      end
      res="A#{base}\r"
      io.print res
      warn res
    end
  end
end

sv=FPIO.new(*ARGV)
sv.start
sleep
