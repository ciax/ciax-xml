#!/usr/bin/ruby
require "libmodxml"

# Rsp Methods
class DevRsp
  include ModXml

  def initialize(ddb)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/rsp".upcase)
    @var=Hash.new
    @par=Array.new
  end

  def rspframe(sel)
    @var[:sel]=sel || @v.err("No Selection")
    @frame=yield || @v.err("No String")
    if tm=attr(@ddb['rspframe'],'terminator')
      @frame.chomp!(tm)
      @v.msg{"Remove terminator:[#{@frame}]" }
    end
    fld=Hash.new
    setframe(@ddb['rspframe'],fld)
    if cc=fld.delete('cc')
      cc == @var[:cc] || @v.err("Verifu:CC Mismatch[#{cc}]!=[#{@var[:cc]}]")
      @v.msg{"Verify:CC OK"}
    end
    fld
  end

  def par=(ary)
    @par=ary
  end

  private
  def setframe(e,fld)
    frame=String.new
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'ccrange'
        @v.msg{"Entering Ceck Code Node"}
        rc=@ddb['rspccrange']
        @var[:cc] = checkcode(rc,setframe(rc,fld))
        @v.msg{"Exitting Ceck Code Node"}
      when 'selected'
        @v.msg{"Entering Selected Node"}
        frame << setframe(@var[:sel],fld)
        @v.msg{"Exitting Selected Node"}
      when 'field'
        frame << field(c,fld)
      when 'repeat'
        repeat(c){|d| frame << field(d,fld) }
      end
    }
    frame
  end

  def field(e,fld)
    str=''
    data=''
    @v.msg{"Field:#{e.attributes['label']}"}
    e.each_element {|d|
      case d.name
      when 'length'
        len=d.text.to_i
        @frame.size >= len || @v.err("Too short (#{@frame.size-len})")
        str=@frame.slice!(0,len)
        @v.msg{"CutFrame:[#{str}] by size=[#{len}]"}
        data=decode(e,str)
      when 'regexp'
        str=@frame.slice!(/#{d.text}/)
        @v.msg{"CutFrame:[#{str}] by regexp=[#{d.text}]"}
        data=decode(e,str)
      when 'assign'
        key=subnum(d.text)
        fld[key]=data
        @v.msg{"Assign:[#{key}]<-[#{fld[key]}]"}
      when 'verify'
        if txt=text(d)
          @v.msg{"Verify:[#{txt}]"}
          txt == data || @v.err("Verify Mismatch[#{data}]!=[#{txt}]")
        end
      end
    }
    str
  end

end
