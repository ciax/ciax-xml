#!/usr/bin/ruby
require "libmodxml"
require "libconvstr"

# Rsp Methods
class DevRsp
  include ModXml

  def initialize(ddb)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/rsp".upcase)
    @cs=ConvStr.new(@v)
  end

  def rspframe(sel)
    @sel=sel || @v.err("No Selection")
    @frame=yield || @v.err("No String")
    if tm=@ddb['rspframe'].attributes['terminator']
      @frame.chomp!(eval('"'+tm+'"'))
      @v.msg{"Remove terminator:[#{@frame}] by [#{tm}]" }
    end
    fld=Hash.new
    setframe(@ddb['rspframe'],fld)
    if cc=fld.delete('cc')
      cc == @cc || @v.err("Verifu:CC Mismatch[#{cc}]!=[#{@cc}]")
      @v.msg{"Verify:CC OK"}
    end
    fld
  end

  def par=(ary)
    @cs.set_par(ary)
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
        @cc = checkcode(rc,setframe(rc,fld))
        @v.msg{"Exitting Ceck Code Node"}
      when 'selected'
        @v.msg{"Entering Selected Node"}
        frame << setframe(@sel,fld)
        @v.msg{"Exitting Selected Node"}
      when 'field'
        frame << field(c,fld)
      when 'repeat'
        frame << repeat_field(c,fld)
      end
    }
    frame
  end

  def repeat_field(e,fld)
    frame=String.new
    @cs.repeat(e){|f|
      case f.name
      when 'repeat'
        frame << repeat_field(f,fld)
      when 'field'
        frame << field(f,fld)
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
        key=@cs.sub_var(d.text)
        fld[key]=data
        @v.msg{"Assign:[#{key}]<-[#{fld[key]}]"}
      when 'verify'
        if txt=d.text
          @v.msg{"Verify:[#{txt}]"}
          txt == data || @v.err("Verify Mismatch[#{data}]!=[#{txt}]")
        end
      end
    }
    str
  end

end
