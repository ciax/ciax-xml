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
        frame << frame_to_field(c)
      when 'array'
        frame << field_array(c)
      end
    }
    frame
  end

  def frame_to_field(e)
    frame,data,key='','',''
    a=e.attributes
    @v.msg{"Field:#{a['label']}"}
    e.each_element {|d|
      case d.name
      when 'length','regexp'
        data=decode(e,cut_frame(d,frame))
      when 'assign'
        key=@cs.sub_var(d.text)
        @field[key]=data
        @v.msg{"Assign:[#{key}]<-[#{data}]"}
      when 'verify'
        if txt=d.text
          @v.msg{"Verify:[#{txt}]"}
          txt == data || @v.err("Verify Mismatch[#{data}]!=[#{txt}]")
          return frame
        end
      end
    }
    frame
  end


  def field_array(e)
    a=e.attributes
    key,frame,cut='',''
    idxs=[]
    @v.msg{"Array:#{a['label']}"}
    e.each_element{ |f|
      case f.name
      when 'length','regexp'
        cut=f
      when 'assign'
        key=@cs.sub_var(f.text)
        @v.msg{"ArrayAssign:[#{key}]"}
      when 'index'
        idxs << @cs.sub_var(f.text)
      end
    }
    @field[key]=array_rec(idxs,@field[key]||[]){
      decode(e,cut_frame(cut,frame))
    }
    frame
  end

  def array_rec(idx,fld=[]) # make recursive array
    f,l=idx.shift.split(':').map{ |i| eval(i) }
    Range.new(f,l||f).each{ |i|
      @v.msg{"ArrayIndex:[#{i}]"}
      fld[i] = idx.empty? ? yield : array_rec(idx.clone,fld[i]||[]){yield}
    }
    fld
  end

  def cut_frame(e,frame)
    case e.name
    when 'length'
      len=e.text.to_i
      @frame.size >= len || @v.err("Too short (#{@frame.size-len})")
      str=@frame.slice!(0,len)
      frame << str
      @v.msg{"CutFrame:[#{str}] by size=[#{len}]"}
      if r=e.attributes['slice']
        str=str.slice(*r.split(':').map{|i| i.to_i })
        @v.msg{"PickFrame:[#{str}] by range=[#{r}]"}
      end
    when 'regexp'
      str=@frame.slice!(/#{e.text}/)
      frame << str
      @v.msg{"CutFrame:[#{str}] by regexp=[#{e.text}]"}
    end
    str
  end
end
