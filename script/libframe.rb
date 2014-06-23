#!/usr/bin/ruby
require 'libmsg'

module CIAX
  class Frame # For Command/Response Frame
    include Msg
    attr_reader :cc
    def initialize(endian=nil,ccmethod=nil,terminator=nil)
      # terminator: frame pointer will jump to terminator if no length or delimiter is specified
      @ver_color=6
      @endian=endian
      @ccrange=nil
      @method=ccmethod
      @terminator=terminator && eval('"'+terminator+'"')
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
        verbose("Frame","RSP:Set [#{frame.inspect}]")
        @frame=frame
      end
      self
    end

    def cut(e0,delimiter=nil)

    end



    # Assign or Ignore mode
    # If cut str incldes terminetor, str will be trimmed
    def cut(e0,delimiter=nil)
      return verify(e0) if e0['val'] # Verify value
      body,sep,rest=@terminator ? @frame.partition(@terminator) : [@frame]
      if len=e0['length']
        verbose("Frame","RSP:Cut by Size [#{len}]")
        if len.to_i > body.size
          warning("Frame","RSP:Cut reached terminator [#{body.size}/#{len}] ")
          str=body
          @frame=rest.to_s
        else
          str=body.slice!(0,len.to_i)
          @frame=[body,sep,rest].join
        end
        cc_add(str)
      elsif delimiter
        verbose("Frame","RSP:Cut by Delimiter [#{delimiter.inspect}] from [#{@frame.inspect}]")
        delimiter=eval('"'+delimiter+'"')
        str,dlm,body=body.partition(delimiter)
        @frame=[body,sep,rest].join
        cc_add([str,dlm].join)
      else
        verbose("Frame","RSP:Cut all the rest")
        str=body
        @frame=[sep,rest].join
        cc_add(str)
      end
      return '' if str.empty?
      len=str.size
      verbose("Frame","RSP:Cut to Assign: [#{str.inspect}]")
      # Pick Part
      if r=e0['slice']
        str=str.slice(*r.split(':').map{|i| i.to_i })
        verbose("Frame","RSP:Pick: [#{str.inspect}] by range=[#{r}]")
      end
      verbose("Frame","RSP:Rest(#{@frame.size}): [#{@frame.inspect}]")
      @fragment=decode(e0,str)
    end

    # Check Code
    def cc_add(str) # Add to check code
      @ccrange << str if @ccrange
      verbose("Frame","CC: Add to Range Frame [#{str.inspect}]")
      self
    end

    def cc_mark # Check Code Start
      verbose("Frame","CC: Mark Range Start" )
      @ccrange=''
      self
    end

    def cc_set # Check Code End
      verbose("Frame","CC: Frame [#{@ccrange.inspect}]")
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
      verbose("Frame","CC: Calc [#{@method.upcase}] -> (#{chk})")
      @ccrange=nil
      @cc=chk.to_s
    end

    def cc_check(cc)
      return self unless cc
      if  cc == @cc
        verbose("Frame","CC: Verify OK [#{cc}]")
      else
        vfy_err("Frame:CC Mismatch:[#{cc}] (should be [#{@cc}])")
      end
      self
    end

    private
    def verify(e0)
      ref=e0['val']
      verbose("Frame","RSP:Verify(#{e0['label']}):[#{ref.inspect}])")
      len=e0['length']||ref.size
      str=@frame.slice!(0,len.to_i)
      if e0['decode']
        val=decode(e0,str)
        ref=eval(ref).to_s
      else
        val=str
      end
      if ref == val
        verbose("Frame","RSP:Verify:(#{e0['label']}) [#{ref.inspect}] OK")
      else
        warning("Frame","RSP:Mismatch(#{e0['label']}):[#{val.inspect}] (should be [#{ref.inspect}])")
      end
      cc_add(str)
      str
    end

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
