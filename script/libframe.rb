#!/usr/bin/ruby
require 'libmsg'

module CIAX
  class Frame # For Command/Response Frame
    include Msg
    attr_reader :cc
    def initialize(endian=nil,ccmethod=nil,terminator=nil,delimiter=nil)
      @ver_color=6
      @endian=endian
      @ccrange=nil
      @method=ccmethod
      @terminator=terminator && eval('"'+terminator+'"')
      @delimiter=delimiter && eval('"'+delimiter+'"')
      reset
    end

    #For Command
    def reset
      @frame=''
      verbose("Frame","CMD:Reset")
      self
    end

    def add(frame,e={})
      if frame
        code=encode(e,frame)
        @frame << code
        @ccrange << code if @ccrange
        verbose("Frame","CMD:Add [#{frame.inspect}]")
      end
      self
    end

    def copy
      verbose("Frame","CMD:Copy [#{@frame.inspect}]")
      @frame
    end

    #For Response
    def set(frame='')
      if frame && !frame.empty?
        if tm=@terminator
          frame.chomp!(tm)
          verbose("Frame","RSP:Remove terminator:[#{tm.inspect}]")
        end
        verbose("Frame","RSP:Set [#{frame.inspect}]")
        @frame=frame
      end
      self
    end

    def cut(e0)
      if len=e0['length']
        str=@frame.slice!(0,len.to_i)
      elsif @delimiter
        str=@frame.slice!(/^.*?#@delimiter/) || ''
        len=(str.delete!(@delimiter)||'').size
      end
      return '' if str.empty?
      # Check Code
      @ccrange << str if @ccrange
      verbose("Frame","RSP:Cut: [#{str.inspect}] by size=[#{len}]")
      # Pick Part
      if r=e0['slice']
        str=str.slice(*r.split(':').map{|i| i.to_i })
        verbose("Frame","RSP:Pick: [#{str.inspect}] by range=[#{r}]")
      end
      @fragment=decode(e0,str)
    end

    def verify(e0)
      return self unless val=e0['val']
      str=@fragment
      val=eval(val).to_s if e0['decode']
      verbose("Frame","RSP:Verify:(#{e0['label']}) [#{val}]")
      if val != str
        vfy_err("Frame:RSP:Mismatch(#{e0['label']}):[#{str}] (should be [#{val}])")
      end
      @fragment=nil
      self
    end

    # Check Code
    def cc_mark # Check Code Start
      verbose("Frame","Mark CC range" )
      @ccrange=''
      self
    end

    def cc_set # Check Code End
      verbose("Frame","CC Frame [#{@ccrange.inspect}]")
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
      verbose("Frame","Calc:CC [#{@method.upcase}] -> (#{chk})")
      @ccrange=nil
      @cc=chk.to_s
    end

    def cc_check(cc)
      return self unless cc
      if  cc == @cc
        verbose("Frame","Verify:CC OK [#{cc}]")
      else
        vfy_err("Frame:CC Mismatch:[#{cc}] (should be [#{@cc}])")
      end
      self
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
      verbose("Frame","RSP:Decode:(#{cdc}) [#{code.inspect}] -> [#{num}]")
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
        verbose("Frame","CMD:Encode:[#{str}](#{len}) -> [#{code.inspect}]")
        str=code
      end
      str
    end
  end
end
