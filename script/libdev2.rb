#!/usr/bin/ruby
require "libxmldoc"
require "libiocmd"
require "libiofile"

# Common Method
module Common
  def checkcode(e,frame)
    chk=0
    if method=e.attributes['method']
      case method
      when 'len'
        chk=frame.length
      when 'bcc'
        frame.each_byte {|c| chk ^= c }
      else
        @v.err "No such CC method #{method}"
      end
      @v.msg("Calc:CC [#{method.upcase}] -> [#{chk}]")
      return chk.to_s
    end
    @v.err "CC No method"
  end

  Pack={'hexstr'=>'hex','chr'=>'C','bew'=>'n','lew'=>'v'}

  def decode(e,code)
    if upk=Pack[e.attributes['unpack']]
      str=(upk == 'hex') ? code.hex : code.unpack(upk).first
      @v.msg("Decode:unpack(#{upk}) [#{code}] -> [#{str}]")
      code=str
    end
    return format(e,code)
  end

  def encode(e,str)
    if pack=Pack[e.attributes['pack']]
      code=[str.to_i(0)].pack(pack)
      @v.msg("Encode:pack(#{pack}) [#{str}] -> [#{code}]")
      str=code
    end
    format(e,str)
  end

  def format(e,code)
    if fmt=e.attributes['format']
      str=fmt % code
      @v.msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]")
      code=str
    end
    code.to_s
  end
end

# Rsp Methods
module Response
  include Common
  def rspframe(sel,frame)
    @v.err("RSP:No Selection") unless @sel=sel
    @v.err("RSP:No String") unless @frame=frame
    setframe(@doc.elements['//rspframe'])
    if @stat['cc']
      if @stat['cc'] === @var[:cc]
        @v.msg("RSP:Verify:CC OK")
      else
        @v.err("RSP:Verifu:CC Mismatch[#{@stat['cc']}]!=[#{@var[:cc]}]") 
      end
      @stat.delete('cc')
    end
    @stat
  end

  def setframe(e)
    frame=String.new
    e.each_element { |c|
      a=c.attributes
      case c.name
      when 'ccrange'
        @v.msg("RSP:Entering Ceck Code Node")
        @var[:cc] = checkcode(c,setframe(c))
      when 'select'
        @v.msg("RSP:Entering Selected Node")
        frame << setframe(@sel)
      when 'assign'
        frame << assign(c,c.text)
      when 'repeat_assign'
        (a['min'].to_i .. a['max'].to_i).each {|n|
          frame << assign(c,c.text % n)
        }
      when 'verify'
        @v.msg("RSP:Verify:#{a['label']}[#{c.text}]")
        frame << s=cut_frame(c)
        @v.err("RSP:Verify Mismatch") if c.text != decode(c,s)
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
          @sel=@doc.select_id('//session/recv',opt) if opt=a['option']
          break
        }
#        @v.wrn(label+":Unknown code [#{str}]")
      end
    }
    frame
  end

  def assign(e,key)
    @v.msg("RSP:Assign:#{e.attributes['label']}[#{key}]")
    code=cut_frame(e)
    @stat[key]=decode(e,code)
    code
  end

  def cut_frame(e)
    if l=e.attributes['length']
      len=l.to_i
      @v.err("RSP:Too short (#{@frame.size-len})") if @frame.size < len
      @frame.slice!(0,len)
    elsif d=e.attributes['delimiter']
      @frame.slice!(/$.+#{d}/)
    else
      @v.err("No frame length or delimiter")
    end
  end
end

# Cmd Methods
module Command
  include Common
  def setpar(par)
    @var['par']=par
  end

  def cmdframe(sel)
    @v.err("CMD:No Selection") unless @sel=sel
    cfn=@doc.elements['//cmdframe']
    if ccn=cfn.elements['.//ccrange']
      @v.msg("CMD:Getting Ceck Code Range")
      @var['ccrange']=getframe(ccn)
      @var['cc_cmd']=checkcode(ccn,@var['ccrange'])
    end
    getframe(cfn)
  end

  def getframe(e)
    frame=String.new
    e.each_element { |c|
      case c.name
      when 'select'
        @v.msg("CMD:Entering Selected Node")
        frame << getframe(@sel)
        @v.msg("CMD:Exitting Selected Node")
      when 'data'
        frame << encode(c,c.text)
      else
        frame << encode(c,@var[c.name])
      end
      @v.msg("CMD:GetFrame:#{c.attributes['label']} [#{frame}]")
    }
    frame
  end
end

# Main
class Dev
  include Command
  include Response
  def initialize(dev,obj=nil)
    id=obj||dev
    begin
      @doc=XmlDoc.new('ddb',dev)
    rescue RuntimeError
      abort $!.to_s
    else
      @f=IoFile.new(id)
      begin
        @stat=@f.load_stat
      rescue
        warn $!
        @stat={'device'=>dev}
      end
      @v=Verbose.new("#{@doc.root.name}/#{id}".upcase)
      @property=@doc.property
      @var=Hash.new
   end
  end

  def setcmd(line)
    cmd,par=line.split(' ')
    @session=@doc.select_id('//session',cmd)
    setpar(par)
    warn @session.attributes['label']
  end

  def getcmd
    print cmdframe(@session.elements['send'])
  end

  def getstat(frame)
    rspframe(@session.elements['recv'],frame)
  end
end

class DevCom
  include Command
  include Response
  attr_reader :stat
  def initialize(dev,iocmd,obj=nil)
    id=obj||dev
    begin
      @doc=XmlDoc.new('ddb',dev)
    rescue RuntimeError
      abort $!.to_s
    else
      @f=IoFile.new(id)
      @ic=IoCmd.new(iocmd,id)
      begin
        @stat=@f.load_stat
      rescue
        warn $!
        @stat={'device'=>dev}
      end
      @v=Verbose.new("#{@doc.root.name}/#{id}".upcase)
      @property=@doc.property
      @var=Hash.new
   end
  end

  def devcom
    i=nil
    @session.each_element {|io|
      case io.name
      when 'send'
        print sndstr=cmdframe(io)
        @ic.snd(sndstr,['snd',i,cmd,par])
      when 'recv'
        rcvstr=gets(nil)
        rcvstr=@ic.rcv(['rcv',i,cmd])
        @stat['time']="%.3f" % @ic.time.to_f
        rspframe(io,rcvstr)
      end
      i=(i||0)+1
    }
    @stat
  end

end
