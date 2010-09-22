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
    @fp=0
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
      @v.msg{"Verify:CC OK [#{cc}]"}
    end
    @field
  end

  def par=(ary)
    @cs.par=ary
   end

  private
  def setframe(e)
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'ccrange'
        @v.msg{"Entering Ceck Code Node"}
        rc=@ddb['rspccrange']
        fst=@fp;setframe(rc)
        @cc = checkcode(rc,@frame.slice(fst...@fp))
        @v.msg{"Exitting Ceck Code Node"}
      when 'selected'
        @v.msg{"Entering Selected Node"}
        setframe(@sel)
        @v.msg{"Exitting Selected Node"}
      when 'field'
        frame_to_field(c)
      when 'array'
        field_array(c)
      end
    }
  end

  def frame_to_field(e)
    data,key='','',''
    a=e.attributes
    @v.msg{"Field:#{a['label']}"}
    e.each_element {|d|
      case d.name
      when 'length','regexp'
        data=decode(e,cut_frame(d))
      when 'assign'
        key=@cs.sub_var(d.text)
        @field[key]=data
        @v.msg{"Assign:[#{key}]<-[#{data}]"}
      when 'verify'
        if txt=d.text
          @v.msg{"Verify:[#{txt}]"}
          txt == data || @v.err("Verify Mismatch[#{data}]!=[#{txt}]")
        end
      end
    }
  end

  def field_array(e)
    a=e.attributes
    key,cut=''
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
    @field[key]=mk_array(idxs,@field[key]){
      decode(e,cut_frame(cut))
    }
  end

  def mk_array(idxary,field) 
    # make multidimensional array
    # i.e. idxary=[0,0:10,0] -> field[0][0][0] .. field[0][10][0]
    return yield if idxary.empty?
    fld=field||[]
    idx=idxary.dup
    f,l=idx.shift.split(':').map{|i| eval(i)}
    Range.new(f,l||f).each{ |i|
      @v.msg{"ArrayIndex:[#{i}]"}
      fld[i] = mk_array(idx,fld[i]){yield}
    }
    fld
  end

  def cut_frame(e)
    case e.name
    when 'length'
      len=e.text.to_i
      str=@frame.slice(@fp,len)
      @fp+=len
      @v.msg{"CutFrame:[#{str}] by size=[#{len}]"}
      if r=e.attributes['slice']
        str=str.slice(*r.split(':').map{|i| i.to_i })
        @v.msg{"PickFrame:[#{str}] by range=[#{r}]"}
      end
    when 'regexp'
      str=@frame.slice(/#{e.text}/)
      @fp+=str.length
      @v.msg{"CutFrame:[#{str}] by regexp=[#{e.text}]"}
    end
    str
  end
end
