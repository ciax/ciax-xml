#!/usr/bin/ruby
require "libmodxml"

# Rsp Methods
class DevRsp
  include ModXml

  def initialize(ddb,var)
    @ddb,@var=ddb,var
    @v=Verbose.new("ddb/#{@ddb['id']}/rsp".upcase)
    @frame=''
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
      @v.msg{"Split:[#{frame}] by [#{dm}]" }
    else
      @fary=[frame]
    end
    setframe(@ddb['rspframe'])
    if cc=@var.stat.delete('cc')
      cc == @cc || @v.err("Verifu:CC Mismatch[#{cc}]!=[#{@cc}]")
      @v.msg{"Verify:CC OK [#{cc}]"}
    end
    @var.stat
  end

  def init_field
    @v.msg(1){"Field:Initialize"}
    begin
      @ddb['rspselect'].each_element{ |e| # response
        e.each_element{|f| #field|array|vefiry
          assign=f.attributes['assign'] || next
          case f.name
          when 'field'
            @v.msg{"Field:Init Field[#{assign}]"}
            @var.stat[assign]=yield
          when 'array'
            @v.msg{"Field:Init Array[#{assign}]"}
            sary=[]
            f.each_element{ |d|
              sary << d.attributes['size'].to_i
            }
            @var.stat[assign]=init_array(sary){yield}
          end
        }
      }
    ensure
      @v.msg(-1){"Field:Initialized"}
    end
  end

  private
  def init_array(sary,field=nil)
    return yield if sary.empty?
    a=field||[]
    sad=sary.dup
    size=sad.shift
    size.times{|i|
      a[i]=init_array(sad,a[i]){yield}
    }
    a
  end

  def setframe(e)
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'ccrange'
        begin
          @v.msg(1){"Entering Ceck Code Node"}
          rc=@ddb['rspccrange']
          fst=@fp;setframe(rc)
          @cc = checkcode(rc,@frame.slice(fst...@fp))
        ensure
          @v.msg(-1){"Exitting Ceck Code Node"}
        end
      when 'selected'
        begin
          @v.msg(1){"Entering Selected Node"}
          setframe(@sel)
        ensure
          @v.msg(-1){"Exitting Selected Node"}
        end
      when 'field'
        frame_to_field(c)
      when 'array'
        field_array(c)
      end
    }
  end

  def frame_to_field(e)
    a=e.attributes
    @v.msg(1){"Field:#{a['label']}"}
    begin
      data=decode(e,cut_frame(e))
      if key=a['assign']
        @var.stat[key]=data
        @v.msg{"Assign:[#{key}]<-[#{data}]"}
      end
      e.each_element {|d| # Verify
      if txt=d.text
        @v.msg{"Verify:[#{txt}]"}
        txt == data || @v.err("Verify Mismatch[#{data}]!=[#{txt}]")
      end
      }
    ensure    
      @v.msg(-1){"Field:End"}
    end
  end

  def field_array(e)
    idxs=[]
    a=e.attributes
    @v.msg(1){"Array:#{e.attributes['label']}"}
    begin
      key=a['assign'] || @v.err("No key for Array")
      e.each_element{ |f| # Index
        idxs << @var.sub_var(f.text)
      }
      @var.stat[key]=mk_array(idxs,@var.stat[key]){
        decode(e,cut_frame(e))
      }
    ensure
      @v.msg(-1){"Array:Assign[#{key}]"}
    end
  end

  def mk_array(idxary,field) 
    # make multidimensional array
    # i.e. idxary=[0,0:10,0] -> field[0][0][0] .. field[0][10][0]
    return yield if idxary.empty?
    fld=field||[]
    idx=idxary.dup
    f,l=idx.shift.split(':').map{|i| eval(i)}
    Range.new(f,l||f).each{ |i|
      @v.msg{"Array:Index[#{i}]"}
      fld[i] = mk_array(idx,fld[i]){yield}
    }
    fld
  end

  def cut_frame(e)
    if @fp >= @frame.size
      @v.err("No more string in frame") if @fary.empty?
      @frame=@fary.shift
      @fp=0
    end
    len=e.attributes['length']||@frame.size
    str=@frame.slice(@fp,len.to_i)
    @fp+=len.to_i
    @v.msg{"CutFrame:[#{str}] by size=[#{len}]"}
    if r=e.attributes['slice']
      str=str.slice(*r.split(':').map{|i| i.to_i })
      @v.msg{"PickFrame:[#{str}] by range=[#{r}]"}
    end
    str
  end
end
