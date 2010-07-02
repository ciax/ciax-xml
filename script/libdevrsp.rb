#!/usr/bin/ruby
require "libmodxml"

# Rsp Methods
class DevRsp < Hash
  include ModXml

  def initialize(ddb)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/rsp".upcase)
  end

  def rspframe(sel)
    @v.err(self[:sel]=sel){"No Selection"}
    @v.err(@frame=yield){"No String"}
    @field=Hash.new
    setframe(@ddb['rspframe'])
    if self['cc']
      @v.err(self['cc'] == self[:cc]){
        "Verifu:CC Mismatch[#{self['cc']}]!=[#{self[:cc]}]"}
      @v.msg{"Verify:CC OK"}
      delete('cc')
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
      when 'assign'
        frame << assign(c,c.text)
      when 'repeat'
        Range.new(*a['range'].split(':')).each {|n|
          c.each_element {|d|
            case d.name
            when 'assign'
              frame << assign(d,d.text % n)
            when 'verify'
              frame << verify(d)
            end
          }
        }
      when 'verify'
        frame << verify(c)
      when 'rspcode'
        frame << s=cut_frame(c)
        label="ResponseCode:#{a['label']}:"
        str=decode(c,s)
        c.each_element {|g| #Match each case
          a=g.attributes
          next if g.text && g.text != str
          msg=label+a['msg']+" [#{str}]"
          case a['type']
          when 'pass'
            @v.msg{msg}
          when 'warn'
            @v.wrn{msg}
          when 'error'
            @v.err{msg}
          end
          self[:sel]=@ddb.select_id(opt) if opt=a['option']
          break true
        } || @v.wrn{label+":Unknown code [#{str}]"}
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

  def assign(e,key)
    code=cut_frame(e)
    key=substitute(key,self)
    @field[key]=decode(e,code)
    @v.msg{"Assign:#{e.attributes['label']}[#{key}]<-[#{@field[key]}]"}
    code
  end

  def cut_frame(e)
    a=e.attributes
    if l=a['length']
      len=l.to_i
      @v.err(@frame.size >= len){"Too short (#{@frame.size-len})"}
      @v.msg{"CutFrame:size=[#{len}]"}
      @frame.slice!(0,len)
    elsif d=a['delimiter']
      str=@frame.slice!(/.+?#{d}/).chop
      @v.msg{"CutFrame:[#{str}] by delimiter [#{d}]"}
      str
    elsif d=a['regexp']
      str=@frame.slice!(/#{d}/)
      @v.msg{"CutFrame:[#{str}] by regexp [#{d}]"}
      str
    else
      @v.err{"No frame length or delimiter"}
    end
  end
end
