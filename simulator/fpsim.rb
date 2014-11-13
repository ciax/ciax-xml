#!/usr/bin/ruby
# Field Point I/O Simulator
require 'gserver'

class Word
  def initialize(n=0)
    @num=n
  end

  def [](pos)
    @num[pos]
  end

  def []=(pos,bin)
    mask(1 << pos,bin << pos)
  end

  def mask(cmask,data=0) #change bit
    stay=@num & (0xffff ^ cmask)
    @num=stay + data
    self
  end

  def to_x
    "%04X" % @num
  end

  def to_b
    "%016b" % @num
  end

  def to_s
    @num
  end

  def xbcc
    chk=0
    to_x.each_byte{|c| chk += c }
    "%02X" % (chk%256)
  end
end

class FPIO < GServer
  def initialize(port=10002,*args)
    super(port,*args)
    Thread.abort_on_exception=true
    @input=Word.new(1366)
    @output=Word.new(5268)
    #Input[index] vs Output[value] table
    #GV(0-1),ArmRot(2-3),RoboH1(4-7),RoboH2(8-11)
    @drvtbl=[6,7,12,13,2,3,2,3,4,5,4,5]
  end

  def serve(io)
    while str=io.gets("\r")
      sleep 0.1
      warn str
      case str
      when /^>02!JCD/
        base=@output.to_x+@output.xbcc
      when /^>03!JCE/
        base=@input.to_x+@input.xbcc
      when /^>02!L/
        base=nil
        cmask=$'[0,4].hex
        data=$'[4,4].hex
        @output.mask(cmask,data)
        @drvtbl.each_with_index{|p,i|
          if @input[i] != @output[p]
            Thread.new{
              sleep (i < 4 ? 1 : 0)
              @input[i]=@output[p]
            }
          end
        }
      end
      res="A#{base}\r"
      io.print res
      warn res
    end
  rescue
    warn $!
  end
end

sv=FPIO.new(*ARGV)
sv.start
sleep
