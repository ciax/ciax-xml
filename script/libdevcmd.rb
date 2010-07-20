#!/usr/bin/ruby
require "libmodxml"

# Cmd Methods
class DevCmd
  include ModXml
  attr_writer :par

  def initialize(ddb)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/cmd".upcase)
    @par,@sel,@ccrange,@cc=[]
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

  private
  def getframe(e)
    frame=''
    e.each_element { |c|
      label=c.attributes['label']
      case c.name
      when 'data'
        frame << encode(c,text(c))
        @v.msg{"GetFrame:#{label}[#{c.text}]"}
      when 'selected'
        @v.msg{"Entering Selected Node"}
        frame << getframe(@sel)
        @v.msg{"Exitting Selected Node"}
      when 'par'
        @par || @v.err("No Parameter")
        str=validate(c,@par)
        @v.msg{"GetFrame:#{label}(parameter)[#{str}]"}
        frame << encode(c,str)
      when 'ccrange'
        frame << @ccrange
        @v.msg{"GetFrame:(ccrange)[#{@ccrange}]"}
      when 'cc_cmd'
        frame << encode(c,@cc)
        @v.msg{"GetFrame:#{label}(cc)[#{@cc}"}
      end
    }
    frame
  end
end
