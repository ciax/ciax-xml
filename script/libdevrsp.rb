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
    @fary=[]
    @fp=0
  end

  def rspframe(sel)
    @sel=sel || @v.err("No Selection")
    frame=yield || @v.err("No String")
    if tm=@ddb['rspframe'].attributes['terminator']
      frame.chomp!(eval('"'+tm+'"'))
      @v.msg{"Remove terminator:[#{frame}] by [#{tm}]" }
    end
    if dm=@ddb['rspframe'].attributes['delimiter']
      @fary=frame.split(eval('"'+dm+'"'))
      @frame=@fary.shift
      @v.msg{"Split:[#{frame}] by [#{dm}]" }
    else
      @frame=frame
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
    data=decode(e,cut_frame(e))
    a=e.attributes
    @v.msg{"Field:#{a['label']}"}
    if key=a['assign']
      @field[key]=data
      @v.msg{"Assign:[#{key}]<-[#{data}]"}
    end
    e.each_element {|d| # Verify
      if txt=d.text
        @v.msg{"Verify:[#{txt}]"}
        txt == data || @v.err("Verify Mismatch[#{data}]!=[#{txt}]")
      end
    }
  end

  def field_array(e)
    idxs=[]
    a=e.attributes
    @v.msg{"Array:#{e.attributes['label']}"}
    if key=a['assign']
      @v.msg{"ArrayAssign:[#{key}]"}
    end
    e.each_element{ |f| # Index
      idxs << @cs.sub_var(f.text)
    }
    @field[key]=mk_array(idxs,@field[key]){
      decode(e,cut_frame(e))
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
    if len=e.attributes['length']
      str=@frame.slice(@fp,len.to_i)
      @fp+=len.to_i
      @v.msg{"CutFrame:[#{str}] by size=[#{len}]"}
    else
      str=@frame.slice(@fp..-1)
      @v.msg{"GetAllFrame:[#{str}]"}
      @frame=@fary.shift
      @fp=0
    end
    if r=e.attributes['slice']
      str=str.slice(*r.split(':').map{|i| i.to_i })
      @v.msg{"PickFrame:[#{str}] by range=[#{r}]"}
    end
    str
  end
end
