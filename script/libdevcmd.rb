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
    @cs.par=ary
  end

  private
  def getframe(e)
    frame=''
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'parameters'
        c.each_element{|d|
          validate(d,@cs.par.shift){"(#{a['label']})"}
        }
      when 'selected'
        @v.msg{"Entering Selected Node"}
        frame << getframe(@sel)
        @v.msg{"Exitting Selected Node"}
      when 'ccrange'
        frame << @ccrange
        @v.msg{"GetFrame:(ccrange)[#{@ccrange}]"}
      when 'data'
        str=c.text
        @v.msg{"GetFrame:#{a['label']}[#{str}]"}
        frame << encode(c,str)
      when 'eval'
        str=eval(@cs.sub_var(c.text)).to_s
        @v.msg{"GetFrame:(calculated)[#{str}]"}
        frame << encode(c,str)
      when 'csv'
        @cs.sub_var(c.text).split(',').each{|str|
          @v.msg{"GetFrame:(csv)[#{str}]"}
          frame << encode(c,str)
        }
      end
    }
    frame
  end
end
