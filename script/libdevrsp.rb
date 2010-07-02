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
    @v.err(self[:sel]=sel){"No Selection"}
    @v.err(@frame=yield){"No String"}
    if tm=@ddb['rspframe'].attributes['terminator']
      @frame.chomp!(eval('"'+tm+'"'))
      @v.msg{"Cut terminator[#{@frame}] by [#{tm}]" }
    end
    setframe(@ddb['rspframe'])
    if cc=@field.delete('cc')
      @v.err(cc == self[:cc]){
        "Verifu:CC Mismatch[#{cc}]!=[#{self[:cc]}]"}
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
        self[:cc] = checkcode(c,setframe(c))
        @v.msg{"Exitting Ceck Code Node"}
      when 'selected'
        @v.msg{"Entering Selected Node"}
        frame << setframe(self[:sel])
        @v.msg{"Exitting Selected Node"}
      when 'verify'
        frame << verify(c)
      when 'assign'
        frame << assign(c)
      when 'rspcode'
        frame << rspcode(c)
      when 'repeat'
        Range.new(*a['range'].split(':')).each {|n|
          c.each_element {|d|
            case d.name
            when 'assign'
              frame << assign(d,n)
            when 'verify'
              frame << verify(d)
            end
          }
        }
      when 'split_assign'
        fary=@frame.split(a['delimiter'])
        c.each_element { |f| # field
          @field[f.text]=fary.shift
        }
        @frame=fary.join(a['delimiter'])
      end
    }
    frame
  end

  def verify(e)
    str=cut_frame(e)
    if e.text
      @v.msg{"Verify:#{e.attributes['label']} [#{e.text}]"}
      @v.err(e.text == decode(e,str)){"Verify Mismatch"}
    end
    str
  end

  def assign(e,num=nil)
    str=cut_frame(e)
    key=substitute(e.text,self)
    key=key % num if num
    @field[key]=decode(e,str)
    @v.msg{"Assign:#{e.attributes['label']}[#{key}]<-[#{@field[key]}]"}
    str
  end

  def rspcode(e)
    str=cut_frame(e)
    a=e.attributes
    key=a['assign']
    field=decode(e,str)
    @field[key]=field
    @v.msg{"ResponseCode:#{a['label']}:[#{key}]<-[#{field}]"}
    unless e.text == field
      @v.wrn{"Bad Response Code"}
      if opt=a['else_sel']
        @v.wrn{"Select other session:[#{opt}]" }
        self[:sel]=@ddb.select_id(opt)
      end
    end
    str
  end
  
  def cut_frame(e)
    a=e.attributes
    if l=a['length']
      len=l.to_i
      @v.err(@frame.size >= len){"Too short (#{@frame.size-len})"}
      str=@frame.slice!(0,len)
      @v.msg{"CutFrame:[#{str}] by size=[#{len}]"}
    elsif d=a['delimiter']
      str=@frame.slice!(/.+?#{d}/).chop
      @v.msg{"CutFrame:[#{str}] by delimiter=[#{d}]"}
    elsif d=a['regexp']
      str=@frame.slice!(/#{d}/)
      @v.msg{"CutFrame:[#{str}] by regexp=[#{d}]"}
    else
      @v.err{"No frame length or delimiter"}
    end
    str
  end
end
