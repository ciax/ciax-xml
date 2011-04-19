#!/usr/bin/ruby
require "libframe"
require "libfrmmod"
require "libparam0"

# Rsp Methods
class FrmRsp
  include FrmMod

  def initialize(doc,stat)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @doc,@stat,@sel=doc,stat
    @v=Verbose.new("fdb/#{@doc['id']}/rsp".upcase)
    @par=Param0.new
    @stat['frame']=@doc['id']
    init_field
  end

  def setrsp(stm)
    cmd=@doc.select_id('cmdframe',stm.first,'command')
    @par.setpar(cmd,stm)
    xpath="response[@id='#{cmd['response']}']"
    @sel=@doc.select('rspframe',xpath)
    self
  end

  def getfield(time=Time.now)
    return "Send Only" unless @sel
    frame=yield || @v.err("No String")
    tm=@doc['rspframe']['terminator']
    dm=@doc['rspframe']['delimiter']
    @frm=Frame.new(frame,dm,tm)
    getfield_rec(@doc['rspframe'])
    if cc=@stat.delete('cc')
      cc == @cc || @v.err("Verifu:CC Mismatch <#{cc}> != (#{@cc})")
      @v.msg{"Verify:CC OK <#{cc}>"}
    end
    @stat['time']="%.3f" % time.to_f
    Hash[@stat]
  end

  private
  # Fill default values in the Field
  def init_field
    fill=''
    begin
      @v.msg(1){"Field:Initialize"}
      @doc.find_each('rspframe',"*[@assign]"){|e1|
        assign=e1['assign']
        next if @stat[assign]
        case e1.name
        when 'field'
          @v.msg{"Field:Init Field[#{assign}]"}
          @stat[assign]=fill.dup
        when 'array'
          @v.msg{"Field:Init Array[#{assign}]"}
          sary=[]
          e1.each{|e2| sary << e2['size'].to_i}
          @stat[assign]=init_array(sary){fill.dup}
        end
      }
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
  def getfield_rec(e0)
    e0.each{|e1|
      case e1.name
      when 'ccrange'
        begin
          @v.msg(1){"Entering Ceck Code Node"}
          @frm.mark
          getfield_rec(e1)
          @cc = checkcode(e1,@frm.copy)
        ensure
          @v.msg(-1){"Exitting Ceck Code Node"}
        end
      when 'select'
        begin
          @v.msg(1){"Entering Selected Node"}
          getfield_rec(@sel)
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
    begin
      @v.msg(1){"Field:#{e0['label']}"}
      data=decode(e0,@frm.cut(e0))
      if key=e0['assign']
        @stat[key]=data
        @v.msg{"Assign:[#{key}] <- <#{data}>"}
      end
      if val=e0.text
        val=eval(val).to_s if e0['decode'] == 'chr'
        @v.msg{"Verify:[#{val}] and <#{data}>"}
        val == data || @v.err("Verify Mismatch <#{data}> != [#{val}]")
      end
    ensure
      @v.msg(-1){"Field:End"}
    end
  end

  def field_array(e0)
    key=e0['assign'] || @v.err("No key for Array")
    idxs=[]
    begin
      @v.msg(1){"Array:#{e0['label']}[#{key}]"}
      e0.each{|e1| # Index
        idxs << @par.subst(e1['range'])
      }
      @stat[key]=mk_array(idxs,@stat[key]){
        decode(e0,@frm.cut(e0))
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
    Range.new(f,l||f).each{|i|
      @v.msg{"Array:Index[#{i}]"}
      fld[i] = mk_array(idx[1..-1],fld[i]){yield}
    }
    fld
  end
end
