#!/usr/bin/ruby
require 'libmsg'
require 'librerange'
module ModConv
  def validate(str,va=nil)
    if va
      Msg.err("No Parameter") unless str
      num=eval(str)
      @v.msg{"Validate: [#{num}] Match? [#{va}]"}
      va.split(',').each{|r|
        break if ReRange.new(r) == num
      } && Msg.err(" Parameter invalid (#{num}) for [#{va.tr(':','-')}]")
      str=num.to_s
    end
    str
  end

  def conv(e,str) # Num -> Chr
    if fmt=e['format']
      @v.msg{"Formatted code(#{fmt}) [#{str}]"}
      code=fmt % eval(str)
      @v.msg{"Formatted code(#{fmt}) [#{str}] -> [#{code}]"}
      str=code
    end
    str
  end
end
