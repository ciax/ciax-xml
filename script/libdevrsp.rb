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
    @field=Hash.new
    setframe(@ddb['rspframe'])
    if cc=@field.delete('cc')
      cc == @cc || @v.err("Verifu:CC Mismatch[#{cc}]!=[#{@cc}]")
      @v.msg{"Verify:CC OK"}
    end
    @field
  end

  def par=(ary)
    @cs.set_par(ary)
   end

  private
  def setframe(e)
    frame=String.new
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'ccrange'
        @v.msg{"Entering Ceck Code Node"}
        rc=@ddb['rspccrange']
        @cc = checkcode(rc,setframe(rc))
        @v.msg{"Exitting Ceck Code Node"}
      when 'selected'
        @v.msg{"Entering Selected Node"}
        frame << setframe(@sel)
        @v.msg{"Exitting Selected Node"}
      when 'field'
        frame << field(c)
      when 'repeat'
        @cs.repeat(c){|d|
          frame << field(d)
        }
      end
    }
    frame
  end

  def field(e)
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
        @field[key]=data
        @v.msg{"Assign:[#{key}]<-[#{data}]"}
      when 'array'
        key=@cs.sub_var(d.text)
        @field[key] ? @field[key] << data : @field[key]=[data]
        @v.msg{"Assign_Array:[#{key}]<-[#{data}]"}
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
