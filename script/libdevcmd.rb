#!/usr/bin/ruby
require "libmodxml"
require "libconvstr"

# Cmd Methods
class DevCmd
  include ModXml

  def initialize(ddb)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/cmd".upcase)
    @cs=ConvStr.new(@v)
  end

  def cmdframe(sel)
    @sel=sel || @v.err("No Selection")
    if ccn=@ddb['cmdccrange']
      @v.msg{"Entering Ceck Code Range"}
      @ccrange=getframe(ccn)
      @cs.var['cc']=checkcode(ccn,@ccrange)
      @v.msg{"Exitting Ceck Code Range"}
    end
    getframe(@ddb['cmdframe'])
  end

  def par=(ary)
    @cs.set_par(ary)
  end

  private
  def getframe(e)
    frame=''
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'parameters'
        c.each_element{|d|
          validate(d,@cs.par.shift)
        }
      when 'selected'
        @v.msg{"Entering Selected Node"}
        frame << getframe(@sel)
        @v.msg{"Exitting Selected Node"}
      when 'ccrange'
        frame << @ccrange
        @v.msg{"GetFrame:(ccrange)[#{@ccrange}]"}
      when 'data'
        frame << get_data(c)
      when 'eval'
        s=eval(@cs.sub_var(c.text)).to_s
        s.split(',').each{|str|
          @v.msg{"GetFrame:[#{str}]"}
          frame << encode(c,str)
        }
      end
    }
    frame
  end

  def get_data(e)
    a=e.attributes
    str=e.text
    @v.msg{"GetFrame:#{a['label']}[#{str}]"}
    encode(e,str)
  end
end
