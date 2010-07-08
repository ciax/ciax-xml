#!/usr/bin/ruby
require "libmodxml"

# Cmd Methods
class DevCmd < Hash
  include ModXml

  def initialize(ddb)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/cmd".upcase)
  end

  def cmdframe(sel)
    @v.err(self[:sel]=sel){"No Selection"}
    if ccn=@ddb['cmdccrange']
      @v.msg{"Entering Ceck Code Range"}
      self['ccrange']=getframe(ccn)
      self['cc_cmd']=checkcode(ccn,self['ccrange'])
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
      when 'selected'
        @v.msg{"Entering Selected Node"}
        frame << getframe(self[:sel])
        @v.msg{"Exitting Selected Node"}
      when 'data'
        frame << encode(c,text(c))
        @v.msg{"GetFrame:#{label}[#{c.text}]"}
      when 'par'
        @v.err(self[:par]){"No Parameter"}
        str=validate(c,self[:par])
        @v.msg{"GetFrame:#{label}(parameter)[#{str}]"}
        frame << encode(c,str)
      else
        frame << encode(c,self[c.name])
        @v.msg{"GetFrame:#{label}(#{c.name})[#{self[c.name]}]"}
      end
    }
    frame
  end
end
