#!/usr/bin/ruby
# Field Point I/O Simulator
require 'gserver'

class FPIO < GServer
  def initialize(port=10002,*args)
    super(port,*args)
    Thread.abort_on_exception=true
    @input=0
    @output=0
    @drvtbl=[6,7,12,13,2,3,2,3,4,5,4,5]
    @inptbl=[[],[],[4,6],[5,7],[8,10],[9,11],[0],[1],[],[],[],[],[2],[3]]
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
        data=$'[4,4].hex
        cmask=$'[0,4].hex
        smask=0xffff ^ cmask
        chg=data & cmask
        stay=@output & smask
        @output=stay+chg
        base=nil
        db="%016b" % data
warn db
        mb="%016b" % cmask
warn mb
        ib="%016b" % @input
warn ib
        dary=db.split(//).reverse
        i=-1
        ary=mb.split(//).reverse.map{|f|
          c=dary.shift
          i+=1
          next if f != '1'
          @inptbl[i].each{|bit|
warn bit
            ib[16-bit]=c
          }
          c
        }
        warn ary
warn ib
        @input=[ib].pack("b*").unpack("s*").first
warn @input.inspect
warn "%04X" % @input
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
