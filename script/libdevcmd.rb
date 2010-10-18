#!/usr/bin/ruby
require "libmodxml"

# Cmd Methods
class DevCmd
  include ModXml

  def initialize(ddb,var)
    @ddb,@var=ddb,var
    @v=Verbose.new("ddb/#{@ddb['id']}/cmd".upcase)
  end

  def cmdframe(sel)
    @sel=sel || @v.err("No Selection")
    if ccn=@ddb['cmdccrange']
      begin
        @v.msg(1){"Entering Ceck Code Range"}
        @ccrange=getframe(ccn)
        @var.stat['cc']=checkcode(ccn,@ccrange)
      ensure
        @v.msg(-1){"Exitting Ceck Code Range"}
      end
    end
    getframe(@ddb['cmdframe'])
  end

  private
  def getframe(e)
    frame=''
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'parameters'
        i='0'
        c.each_element{|d|
          validate(d,@var[i.next])
        }
      when 'selected'
        begin
          @v.msg(1){"Entering Selected Node"}
          frame << getframe(@sel)
        ensure
          @v.msg(-1){"Exitting Selected Node"}
        end
      when 'ccrange'
        frame << @ccrange
        @v.msg{"GetFrame:(ccrange)[#{@ccrange}]"}
      when 'data'
        str=c.text
        @v.msg{"GetFrame:#{a['label']}[#{str}]"}
        frame << encode(c,str)
      when 'formula'
        str=eval(@var.sub_var(c.text)).to_s
        @v.msg{"GetFrame:(calculated)[#{str}]"}
        frame << encode(c,str)
      when 'csv'
        @var.sub_var(c.text).split(',').each{|str|
          @v.msg{"GetFrame:(csv)[#{str}]"}
          frame << encode(c,str)
        }
      end
    }
    frame
  end
end
