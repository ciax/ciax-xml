#!/usr/bin/ruby
require "libmodxml"
require "libconvstr"

# Rsp Methods
class DevRsp
  include ModXml

  def initialize(ddb,field={})
    @ddb=ddb
    @field=field
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
    setframe(@ddb['rspframe'])
    if cc=@field.delete('cc')
      cc == @cc || @v.err("Verifu:CC Mismatch[#{cc}]!=[#{@cc}]")
      @v.msg{"Verify:CC OK"}
    end
    @field
  end

  def par=(ary)
    @cs.par=ary
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
      end
    }
    frame
  end

  def field(e)
    frame,data,key,fld='','',''
    a=e.attributes
    @v.msg{"Field:#{a['label']}"}
    (a['array']||1).to_i.times{ 
      e.each_element {|d|
        case d.name
        when 'length'
          len=d.text.to_i
          @frame.size >= len || @v.err("Too short (#{@frame.size-len})")
          str=@frame.slice!(0,len)
          frame << str
          @v.msg{"CutFrame:[#{str}] by size=[#{len}]"}
          if r=d.attributes['range']
            str=str[*r.split(':').map{|i| i.to_i }]
            @v.msg{"PickFrame:[#{str}] by range=[#{r}]"}
          end
          data=decode(e,str)
        when 'regexp'
          str=@frame.slice!(/#{d.text}/)
          frame << str
          @v.msg{"CutFrame:[#{str}] by regexp=[#{d.text}]"}
          data=decode(e,str)
        when 'assign'
          key,idx=@cs.sub_var(d.text).split(':')
          if idx
            fld=[*@field[key]]
            fld[idx.to_i]=data
          elsif a['array']
            @v.msg{"Assign_Array:[#{key}]<-[#{data}]"}
            fld=[*fld,data]
          else
            fld=data
            @v.msg{"Assign:[#{key}]<-[#{data}]"}
          end
        when 'verify'
          if txt=d.text
            @v.msg{"Verify:[#{txt}]"}
            txt == data || @v.err("Verify Mismatch[#{data}]!=[#{txt}]")
            return frame
          end
        end
      }
    }
    @field[key]=fld
    frame
  end

  def cut_len(d)
  end


end
