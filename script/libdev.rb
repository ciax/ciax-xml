#!/usr/bin/ruby
require "libxmldoc"
require "libiocmd"
require "libiofile"
require "libnumrange"
require "libmodxml"

# Rsp Methods
class RspFrame < Hash
  include ModXml
  attr_accessor :field

  def initialize(ddb,id)
    @ddb=ddb
    @v=Verbose.new("ddb/#{@ddb['id']}/rsp".upcase)
    @cc=nil
    @f=IoFile.new(id)
    begin
      update(@f.load_stat)
    rescue
      warn $!
      self['device']=@ddb['id']
    end
  end

  def rspframe(sel,frame)
    @v.err("No Selection") unless @sel=sel
    @v.err("No String") unless @frame=frame
    setframe(@ddb['rspframe'])
    if self['cc']
      if self['cc'] == @cc
        @v.msg("Verify:CC OK")
      else
        @v.err("Verifu:CC Mismatch[#{self['cc']}]!=[#{@cc}]") 
      end
      delete('cc')
    end
    @f.save_stat(Hash.new.update(self))
  end

  def setframe(e)
    frame=String.new
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'ccrange'
        @v.msg("Entering Ceck Code Node")
        @cc = checkcode(c,setframe(c))
        @v.msg("Exitting Ceck Code Node")
      when 'selected'
        @v.msg("Entering Selected Node")
        frame << setframe(@sel)
        @v.msg("Exitting Selected Node")
      when 'assign'
        frame << assign(c,c.text)
      when 'repeat_assign'
        Range.new(*a['range'].split(':')).each {|n|
          frame << assign(c,c.text % n)
        }
      when 'verify'
        @v.msg("Verify:#{a['label']} [#{c.text}]")
        frame << s=cut_frame(c)
        @v.err("Verify Mismatch") if c.text != decode(c,s)
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
            @v.msg(msg)
          when 'warn'
            @v.wrn(msg)
          when 'error'
            @v.err(msg)
          end
          @sel=@ddb.select_id(opt) if opt=a['option']
          break true
        } || @v.wrn(label+":Unknown code [#{str}]")
      end
    }
    frame
  end

  def assign(e,key)
    code=cut_frame(e)
    self[key]=decode(e,code)
    @v.msg("Assign:#{e.attributes['label']}[#{key}]<-[#{self[key]}]")
    code
  end

  def cut_frame(e)
    a=e.attributes
    if l=a['length']
      len=l.to_i
      @v.err("Too short (#{@frame.size-len})") if @frame.size < len
      @v.msg("CutFrame:size=[#{len}]")
      @frame.slice!(0,len)
    elsif d=a['delimiter']
      str=@frame.slice!(/.+?#{d}/).chop
      @v.msg("CutFrame:[#{str}] by [#{d}]")
      str
    else
      @v.err("No frame length or delimiter")
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
    @v.err("No Selection") unless @sel=sel
    if ccn=@ddb['cmdframe'].elements['ccrange']
      @v.msg("Entering Ceck Code Range")
      self['ccrange']=getframe(ccn)
      self['cc_cmd']=checkcode(ccn,self['ccrange'])
      @v.msg("Exitting Ceck Code Range")
    end
    getframe(@ddb['cmdframe'])
  end

  def getframe(e)
    frame=String.new
    e.each_element { |c|
      label=c.attributes['label']
      case c.name
      when 'selected'
        @v.msg("Entering Selected Node")
        frame << getframe(@sel)
        @v.msg("Exitting Selected Node")
      when 'data'
        frame << encode(c,c.text)
        @v.msg("GetFrame:#{label}[#{c.text}]")
      else
        str=validate(c,self[c.name])
        frame << encode(c,str)
        @v.msg("GetFrame:#{label}(#{c.name})[#{str}]")
      end
    }
    frame
  end
end

# Main
class Dev
  attr_reader :field

  def initialize(dev,obj=nil)
    id=obj||dev
    begin
      @ddb=XmlDoc.new('ddb',dev)
    rescue RuntimeError
      abort $!.to_s
    else
      @v=Verbose.new("ddb/#{id}".upcase)
      @field=RspFrame.new(@ddb,id)
      @cmd=CmdFrame.new(@ddb)
   end
  end

  def setcmd(cmd)
    @session=@ddb.select_id(cmd)
    @v.msg('Select:'+@session.attributes['label'])
  end

  def setpar(par)
    @cmd['par']=par
  end

  def getcmd(index=0)
    @cmd.cmdframe(@session.elements[index.to_i+1,'send'])
  end

  def getfield(frame,index=0)
    @field.rspframe(@session.elements[index.to_i+1,'recv'],frame)
  end

end

class DevCom < Dev
  def initialize(dev,iocmd,obj=nil)
    super(dev,obj)
    @ic=IoCmd.new(iocmd,obj||dev)
    @cmdcache=Hash.new
  end

  def cmdcache(io,skey)
    if cmd=@cmdcache[skey]
      @v.msg("Cmd cache found")
      cmd
    else
      @cmdcache[skey]=@cmd.cmdframe(io)
    end
  end

  def devcom
    snd='snd0'
    rcv='rcv0'
    cid=@session.attributes['id']
    @session.each_element {|io|
      case io.name
      when 'send'
        sid=[snd,cid,@cmd['par']]
        sndstr=cmdcache(io,sid.join(':'))
        @ic.snd(sndstr,sid)
        snd.succ!
      when 'recv'
        rcvstr=@ic.rcv([rcv,cid])
        @field['time']="%.3f" % @ic.time.to_f
        @field.rspframe(io,rcvstr)
        rcv.succ!
      end
    }
    @field
  end

end
