#!/usr/bin/ruby
require "libxmldoc"
require "libiocmd"
require "libiofile"
require "libnumrange"
require "libmodxml"

# Rsp Methods
class RspFrame < Hash
  include ModXml
  attr_reader :field

  def initialize(ddb,id)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/rsp".upcase)
    @fd=IoFile.new("field_#{id}")
    begin
      @field=@fd.load_stat
    rescue
      warn $!
      @field={'device'=>@ddb['id'] }
    end
  end

  def rspframe(sel,time=Time.now)
    @v.err(self[:sel]=sel){"No Selection"}
    @v.err(@frame=yield){"No String"}
    @field['time']="%.3f" % time.to_f
    setframe(@ddb['rspframe'])
    if self['cc']
      @v.err(self['cc'] == self[:cc]){
        "Verifu:CC Mismatch[#{self['cc']}]!=[#{self[:cc]}]"}
      @v.msg{"Verify:CC OK"}
      delete('cc')
    end
    @fd.save_stat(@field)
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

# Cmd Methods
class CmdFrame < Hash
  include ModXml

  def initialize(ddb)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/cmd".upcase)
  end

  def cmdframe(sel)
    @v.err(self[:sel]=sel){"No Selection"}
    if ccn=@ddb['cmdframe'].elements['ccrange']
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
        frame << encode(c,c.text)
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

# Main
class Dev
  attr_reader :cid,:field

  def initialize(dev,obj=nil)
    id=obj||dev
    begin
      @ddb=XmlDoc.new('ddb',dev)
    rescue RuntimeError
      abort $!.to_s
    else
      @v=Verbose.new("ddb/#{id}".upcase)
      @rsp=RspFrame.new(@ddb,id)
      @cmd=CmdFrame.new(@ddb)
      @cid=String.new
      @cmdcache=Hash.new
      @field=@rsp.field
   end
  end

  def setcmd(cmdary)
    @cid=cmdary.compact.join(':')
    session=@ddb.select_id(cmdary.shift)
    @v.msg{'Select:'+session.attributes['label']}
    @send=session.elements['send']
    @recv=session.elements['recv']
    @cmd[:par]=cmdary.shift
#    @rsp['par']=cmdary
  end

  def getcmd
    return unless @send
    if cmd=@cmdcache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
      cmd
    else
      @cmdcache[@cid]=@cmd.cmdframe(@send)
    end
  end

  def setrsp(time=Time.now)
    return unless @recv
    @rsp.rspframe(@recv,time){yield}
  end

end

class DevCom < Dev
  def initialize(dev,iocmd,obj=nil)
    super(dev,obj)
    id=obj||dev
    @ic=IoCmd.new(iocmd,'device_'+id,@ddb['wait'],1)
  end

  def devcom
    @ic.snd(getcmd,'snd:'+@cid)
    setrsp(@ic.time){ @ic.rcv('rcv:'+@cid) }
  end

end
