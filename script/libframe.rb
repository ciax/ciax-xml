#!/usr/bin/ruby
class Frame
  def initialize(frame,dm=nil,tm=nil) # delimiter,terminator
    @v=Verbose.new("fdb/frm".upcase,6)
    @fp=@mark=0
    @frame=[]
    if tm
      frame.chomp!(eval('"'+tm+'"'))
      @v.msg{"Remove terminator:[#{frame}] by [#{tm}]" }
    end
    if dm
      @fary=frame.split(eval('"'+dm+'"'))
      @v.msg{"Split:[#{frame}] by [#{dm}]" }
    else
      @fary=[frame]
    end
  end

  def mark
    @v.msg{"Mark FP:[#{@fp}]" }
    @mark=@fp
  end

  def copy
    @v.msg{"Copy Frame from [#{@mark}-#{@fp}]"}
    @frame.slice(@mark...@fp)
  end

  def cut(e0)
    if @fp >= @frame.size
      @frame=@fary.shift||''
      @fp=0
    end
    len=e0['length']||@frame.size
    str=@frame.slice(@fp,len.to_i)
    @fp+=len.to_i
    @v.msg{"CutFrame: <#{str}> by size=[#{len}]"}
    if r=e0['slice']
      str=str.slice(*r.split(':').map{|i| i.to_i })
      @v.msg{"PickFrame: <#{str}> by range=[#{r}]"}
    end
    str
  end
end
