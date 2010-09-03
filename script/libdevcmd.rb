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
      @cc=checkcode(ccn,@ccrange)
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
      label=c.attributes['label']
      case c.name
      when 'data'
        frame << encode(c,c.text)
        @v.msg{"GetFrame:#{label}[#{c.text}]"}
      when 'selected'
        @v.msg{"Entering Selected Node"}
        frame << getframe(@sel)
        @v.msg{"Exitting Selected Node"}
      when 'par'
        str=validate(c,@cs.par.shift)
        @v.msg{"GetFrame:#{label}(parameter)[#{str}]"}
        frame << encode(c,calc(c,str))
      when 'ccrange'
        frame << @ccrange
        @v.msg{"GetFrame:(ccrange)[#{@ccrange}]"}
      when 'cc'
        frame << encode(c,@cc)
        @v.msg{"GetFrame:#{label}(cc)[#{@cc}"}
      end
    }
    frame
  end
end
