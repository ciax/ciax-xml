#!/usr/bin/ruby
require 'libmsg'

class Frame
  extend Msg::Ver
  def initialize(endian=nil,ccmethod=nil) # delimiter,terminator
    Frame.init_ver(self,6)
    @endian=endian
    @ccrange=nil
    @method=ccmethod
    @frame=''
  end

  def set(frame='')
    if frame
      Frame.msg{"Frame set <#{frame}>"}
      @frame=frame
    end
    self
  end

  # Command
  def add(frame,e={})
    if frame
      code=encode(e,frame)
      @frame << code
      @ccrange << code if @ccrange
      Frame.msg{"Frame add <#{frame}>"}
    end
    self
  end

  def copy
    Frame.msg{"Copy Frame <#{@frame}>"}
    @frame
  end

  # Response
  def mark
    Frame.msg{"Mark CC range" }
    @ccrange=''
    self
  end

  def cut(e0)
    len=e0['length']||@frame.size
    str=@frame.slice!(0,len.to_i)
    return if str.empty?
    # Check Code
    @ccrange << str if @ccrange
    Frame.msg{"CutFrame: <#{str}> by size=[#{len}]"}
    # Pick Part
    if r=e0['slice']
      str=str.slice(*r.split(':').map{|i| i.to_i })
      Frame.msg{"PickFrame: <#{str}> by range=[#{r}]"}
    end
    str=decode(e0,str)
    # Verify
    if val=e0['val']
      val=eval(val).to_s if e0['decode']
      Frame.msg{"Verify:(#{e0['label']}) [#{val}] and <#{str}>"}
      val == str || Msg.com_err("Verify Mismatch(#{e0['label']}) <#{str}> != [#{val}]")
    end
    str
  end

  def checkcode
    Frame.msg{"CC Frame <#{@ccrange}>"}
    chk=0
    case @method
    when 'len'
      chk=@ccrange.length
    when 'bcc'
      @ccrange.each_byte {|c| chk ^= c }
    when 'sum'
      @ccrange.each_byte {|c| chk += c }
      chk%=256
    else
      Msg.cfg_err("No such CC method #{@method}")
    end
    Frame.msg{"Calc:CC [#{@method.upcase}] -> (#{chk})"}
    @ccrange=nil
    return chk.to_s
  end

  private
  def decode(e,code) # Chr -> Num
    return code.to_s unless cdc=e['decode']
    case cdc
    when 'hexstr' # "FF" -> "255"
      num=code.hex
    when 'decstr' # "80000123" -> "-123"
      # sign: k3n=F, oss=8,
      sign=(/[8Ff]/ === code[0]) ? '-' : ''
      num=sign+code[1..-1].sub(/0+/,'')
    else
      ary=code.unpack("C*")
      ary.reverse! if @endian=='little'
      num=ary.inject(0){|r,i| r*256+i}
      if cdc=='signed'
        p= 256 ** code.size
        num = num < p/2 ? num : num - p
      end
    end
    Frame.msg{"Decode:(#{cdc}) [#{code}] -> [#{num}]"}
    num.to_s
  end

  def encode(e,str) # Num -> Chr
    str=e['format'] % eval(str) if e['format']
    if len=e['length']
      code=''
      num=eval(str)
      len.to_i.times{
        c = (num % 256).chr
        num/=256
        code =(@endian == 'little') ? code+c : c+code
      }
      Frame.msg{"Encode:[#{str}](#{len}) -> [#{code}]"}
      str=code
    end
    str
  end
end
