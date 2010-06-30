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
    @f=IoFile.new(id)
    begin
      @field=@f.load_stat
    rescue
      warn $!
      @field={'device'=>@ddb['id'] }
    end
  end

  def rspframe(sel,frame,time=Time.now)
    @v.err(self[:sel]=sel){"No Selection"}
    @v.err(@frame=frame){"No String"}
    @field['time']="%.3f" % time.to_f
    setframe(@ddb['rspframe'])
    if self['cc']
      @v.err(self['cc'] == self[:cc]){
        "Verifu:CC Mismatch[#{self['cc']}]!=[#{self[:cc]}]"}
      @v.msg{"Verify:CC OK"}
      delete('cc')
    end
    @f.save_stat(@field)
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
      when 'repeat_assign'
        Range.new(*a['range'].split(':')).each {|n|
          frame << assign(c,c.text % n)
        }
      when 'verify'
        @v.msg{"Verify:#{a['label']} [#{c.text}]"}
        frame << s=cut_frame(c)
        @v.err(c.text == decode(c,s)){"Verify Mismatch"}
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
    frame=Array.new
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
        self[:par].each {|par|
          str=validate(c,par)
          @v.msg{"GetFrame:#{label}(parameter)[#{str}]"}
          frame << encode(c,str)
        }
      else
        frame << encode(c,self[c.name])
        @v.msg{"GetFrame:#{label}(#{c.name})[#{self[c.name]}]"}
      end
    }
    frame.join(e.attributes['delimiter'])
  end
end

# Main
class Dev

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
      @cid=Array.new
      @cmdcache=Hash.new
   end
  end

  def setcmd(cmdary)
    @cid=cmdary.clone
    session=@ddb.select_id(cmdary.shift)
    @v.msg{'Select:'+session.attributes['label']}
    @send=session.elements['send']
    @recv=session.elements['recv']
    @cmd[:par]=cmdary
#    @rsp['par']=cmdary
  end

  def getcmd
    return unless @send
    cid=@cid.join(':')
    if cmd=@cmdcache[cid]
      @v.msg{"Cmd cache found [#{cid}]"}
      cmd
    else
      @cmdcache[cid]=@cmd.cmdframe(@send)
    end
  end

  def setrsp(time=Time.now)
    return unless @recv
    @rsp.rspframe(@recv,yield,time)
  end

  def field
    @rsp.field
  end

end

class DevCom < Dev
  def initialize(dev,iocmd,obj=nil)
    super(dev,obj)
    @ic=IoCmd.new(iocmd,obj||dev,@ddb['wait'],1)
  end

  def devcom
    @ic.snd(getcmd,['snd']+@cid)
    setrsp(@ic.time){ @ic.rcv(['rcv']+@cid) }
  end

end

