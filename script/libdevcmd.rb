#!/usr/bin/ruby
require "libmodxml"

# Cmd Methods
class DevCmd
  include ModXml
  attr_writer :par

  def initialize(ddb)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/cmd".upcase)
    @var=Hash.new
  end

  def cmdframe(sel)
    @var[:sel]=sel || @v.err("No Selection")
    if ccn=@ddb['cmdccrange']
      @v.msg{"Entering Ceck Code Range"}
      @var[:ccrange]=getframe(ccn)
      @var[:cc]=checkcode(ccn,@var[:ccrange])
      @v.msg{"Exitting Ceck Code Range"}
    end
    getframe(@ddb['cmdframe'])
  end

  def par=(par)
    @var[:par]=par
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
        frame << getframe(@var[:sel])
        @v.msg{"Exitting Selected Node"}
      when 'par'
        @var[:par] || @v.err("No Parameter")
        str=validate(c,@var[:par])
        @v.msg{"GetFrame:#{label}(parameter)[#{str}]"}
        frame << encode(c,str)
      when 'ccrange'
        frame << @var[:ccrange]
        @v.msg{"GetFrame:(ccrange)[#{@var[:ccrange]}]"}
      when 'cc_cmd'
        frame << encode(c,@var[:cc])
        @v.msg{"GetFrame:#{label}(cc)[#{@var[:cc]}"}
      end
    }
    frame
  end
end
