#!/usr/bin/ruby
require "libmodxml"

# Rsp Methods
class DevRsp < Hash
  include ModXml

  def initialize(ddb)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/rsp".upcase)
    @field=Hash.new
  end

  def rspframe(sel)
    self[:sel]=sel || @v.err("No Selection")
    @frame=yield || @v.err("No String")
    if tm=attr(@ddb['rspframe'],'terminator')
      @frame.chomp!(tm)
      @v.msg{"Remove terminator:[#{@frame}]" }
    end
    setframe(@ddb['rspframe'])
    if cc=@field.delete('cc')
      cc == self[:cc] || @v.err("Verifu:CC Mismatch[#{cc}]!=[#{self[:cc]}]")
      @v.msg{"Verify:CC OK"}
    end
    @field
  end

  private
  def setframe(e)
    frame=String.new
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'ccrange'
        @v.msg{"Entering Ceck Code Node"}
        rc=@ddb['rspccrange']
        self[:cc] = checkcode(rc,setframe(rc))
        @v.msg{"Exitting Ceck Code Node"}
      when 'selected'
        @v.msg{"Entering Selected Node"}
        frame << setframe(self[:sel])
        @v.msg{"Exitting Selected Node"}
      when 'field'
        frame << field(c)
      when 'repeat'
        Range.new(*a['range'].split(':')).each {|n|
          c.each_element {|d|
            frame << field(d,n)
          }
        }
      end
    }
    frame
  end


  def field(e,num=nil)
    str=''
    field=''
    @v.msg{"Field:#{e.attributes['label']}"}
    e.each_element {|d|
      case d.name
      when 'length'
        len=d.text.to_i
        @frame.size >= len || @v.err("Too short (#{@frame.size-len})")
        str=@frame.slice!(0,len)
        @v.msg{"CutFrame:[#{str}] by size=[#{len}]"}
        field=decode(e,str)
      when 'regexp'
        str=@frame.slice!(/#{d.text}/)
        @v.msg{"CutFrame:[#{str}] by regexp=[#{d.text}]"}
        field=decode(e,str)
      when 'assign'
        key=substitute(d,self)
        key=key % num if num
        @field[key]=field
        @v.msg{"Assign:[#{key}]<-[#{@field[key]}]"}
      when 'verify'
        if txt=text(d)
          @v.msg{"Verify:[#{txt}]"}
          txt == field || @v.err("Verify Mismatch[#{field}]!=[#{txt}]")
        end
      end
    }
    str
  end

end
