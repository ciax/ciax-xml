#!/usr/bin/ruby
require "libmodxml"

# Cmd Methods
class DevCmd
  include ModXml

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
      @var['cc']=[@var[:cc]]
      @v.msg{"Exitting Ceck Code Range"}
    end
    getframe(@ddb['cmdframe'])
  end

  def par=(ary)
    @var['par']=ary
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
        @var['par'] || @v.err("No Parameter")
        str=validate(c,@var['par'].shift)
        @v.msg{"GetFrame:#{label}(parameter)[#{str}]"}
        frame << encode(c,str)
      when 'ccrange'
        frame << @var[:ccrange]
        @v.msg{"GetFrame:(ccrange)[#{@var[:ccrange]}]"}
      when 'cc'
        frame << encode(c,@var[:cc])
        @v.msg{"GetFrame:#{label}(cc)[#{@var[:cc]}"}
      when 'ref'
        ref=c.attributes['ref']
        @var[ref] || @v.err("No Reference (#{ref})")
        str=@var[ref].shift
        c.each_element {|d| str=validate(d,str)}
        frame << encode(c,str)
        @v.msg{"GetFrame:#{label}(#{ref})[#{str}"}
      end
    }
    frame
  end
end
