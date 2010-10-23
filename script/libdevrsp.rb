#!/usr/bin/ruby
require "libmodxml"
require "libparam"
# Rsp Methods
class DevRsp
  include ModXml

  def initialize(ddb,stat)
    @ddb,@stat,@sel=ddb,stat
    @v=Verbose.new("ddb/#{@ddb['id']}/rsp".upcase)
    @frame=''
    @fary=[]
    @fp=0
    @par=Param.new
    init_field
  end

  def setrsp(stm)
    @par.setpar(stm)
    cmd=@ddb.select_id('cmdselect',stm.first)
    res=cmd.attributes['response']
    @sel= res ? @ddb.select_id('rspselect',res) : nil
  end

  def getfield(time=Time.now)
    return "Send Only" unless @sel
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
    if cc=@stat.delete('cc')
      cc == @cc || @v.err("Verifu:CC Mismatch[#{cc}]!=[#{@cc}]")
      @v.msg{"Verify:CC OK [#{cc}]"}
    end
    @stat['time']="%.3f" % time.to_f
    Hash[@stat]
  end

  private
  # Fill default values in the Field
  def init_field(fill='')
    @v.msg(1){"Field:Initialize"}
    begin
      @ddb['rspselect'].each_element{ |e0| # response
        e0.each_element{|e1| #field|array|vefiry
          assign=e1.attributes['assign'] || next
          case e1.name
          when 'field'
            @v.msg{"Field:Init Field[#{assign}]"}
            @stat[assign]=fill unless @stat[assign]
          when 'array'
            @v.msg{"Field:Init Array[#{assign}]"}
            sary=[]
            e1.each_element{ |e2|
              sary << e2.attributes['size'].to_i
            }
            @stat[assign]=init_array(sary){fill} unless @stat[assign]
          end
        }
      }
      @stat['device']=@ddb['id']
    ensure
      @v.msg(-1){"Field:Initialized"}
    end
  end

  def init_array(sary,field=nil)
    return yield if sary.empty?
    a=field||[]
    sary[0].times{|i|
      a[i]=init_array(sary[1..-1],a[i]){yield}
    }
    a
  end

  # Process Frame to Field
  def setframe(e0)
    e0.each_element { |e1|
      a=e1.attributes
      case e1.name
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
        frame_to_field(e1)
      when 'array'
        field_array(e1)
      end
    }
  end

  def frame_to_field(e0)
    a=e0.attributes
    @v.msg(1){"Field:#{a['label']}"}
    begin
      data=decode(e0,cut_frame(e0))
      if key=a['assign']
        @stat[key]=data
        @v.msg{"Assign:[#{key}]<-[#{data}]"}
      end
      e0.each_element {|e1| # Verify
      if txt=e1.text
        @v.msg{"Verify:[#{txt}]"}
        txt == data || @v.err("Verify Mismatch[#{data}]!=[#{txt}]")
      end
      }
    ensure    
      @v.msg(-1){"Field:End"}
    end
  end

  def field_array(e0)
    idxs=[]
    a=e0.attributes
    @v.msg(1){"Array:#{e0.attributes['label']}"}
    begin
      key=a['assign'] || @v.err("No key for Array")
      e0.each_element{ |e1| # Index
        idxs << @par.sub_par(e1.text)
      }
      @stat[key]=mk_array(idxs,@stat[key]){
        decode(e0,cut_frame(e0))
      }
    ensure
      @v.msg(-1){"Array:Assign[#{key}]"}
    end
  end

  def mk_array(idx,field)
    # make multidimensional array
    # i.e. idxary=[0,0:10,0] -> field[0][0][0] .. field[0][10][0]
    return yield if idx.empty?
    fld=field||[]
    f,l=idx[0].split(':').map{|i| eval(i)}
    Range.new(f,l||f).each{ |i|
      @v.msg{"Array:Index[#{i}]"}
      fld[i] = mk_array(idx[1..-1],fld[i]){yield}
    }
    fld
  end

  def cut_frame(e0)
    if @fp >= @frame.size
      @v.err("No more string in frame") if @fary.empty?
      @frame=@fary.shift
      @fp=0
    end
    len=e0.attributes['length']||@frame.size
    str=@frame.slice(@fp,len.to_i)
    @fp+=len.to_i
    @v.msg{"CutFrame:[#{str}] by size=[#{len}]"}
    if r=e0.attributes['slice']
      str=str.slice(*r.split(':').map{|i| i.to_i })
      @v.msg{"PickFrame:[#{str}] by range=[#{r}]"}
    end
    str
  end
end
