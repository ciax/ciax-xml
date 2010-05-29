#!/usr/bin/ruby
require "libxmldoc"
require "libiocmd"
require "libiofile"

class Dev
  attr_reader :stat
  def initialize(dev,iocmd,obj=nil)
    id=obj||dev
    begin
      @doc=XmlDoc.new('ddb',dev)
    rescue RuntimeError
      abort $!.to_s
    else
      @f=IoFile.new(id)
      #      @ic=IoCmd.new(iocmd,id)
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

  def devcom(line)
    cmd,par=line.split(' ')
    session=@doc.select_id('//session',cmd)
    setpar(par)
    warn session.attributes['label']
    session.each_element {|io|
      @sel=io
      case io.name
      when 'send'
print        sndstr=cmdframe
#        @ic.snd(sndstr,['snd',cmd,par].compact.join('_'))
      when 'recv'
#        rcvstr=@ic.rcv(['rcv',cmd].compact.join('_'))
#        @stat['time']="%.3f" % @ic.time.to_f
#        rspframe(rcvstr)
      end
    }
  end

  # Rsp Methods
  def rspframe(frame)
    @v.err("RSP:No String") unless frame
    @frame=frame
    getstat(@doc.elements['//rspframe'])
  end

  def getstat(e)
    str=String.new
    e.each_element { |c|
      case c.name
      when 'ccrange'
        @v.msg("RSP:Entering Ceck Code Node")
        @var[:ccc] = checkcode(e,getstat(e))
      when 'select'
        @v.msg("RSP:Entering Selected Node")
        str << getstat(@sel)
      else
        str << s=cut_frame(c)
        
      end
    }
    str
  end

  def cut_frame(e)
    if l=e.attributes['length']
      len=l.to_i
      @v.err("RSP:Too short (#{@frame.size-len})") if @frame.size < len
      @frame.slice!(0,len)
    elsif d=e.attributes['delimiter']
      @frame.slice!(/$.+#{d}/)
    end
  end

  # Cmd Methods
  def setpar(par)
    @var['par']=par
  end

  def cmdframe
    cfn=@doc.elements['//cmdframe']
    if ccn=cfn.elements['.//ccrange']
      @v.msg("CMD:Getting Ceck Code Range")
      @var['ccrange']=getframe(ccn)
      @var['cc_cmd']=checkcode(ccn,@var['ccrange'])
    end
    getframe(cfn)
  end

  def getframe(e)
    str=String.new
    e.each_element { |c|
      case c.name
      when 'select'
        @v.msg("CMD:Entering Selected Node")
        str << getframe(@sel)
        @v.msg("CMD:Exitting Selected Node")
      when 'data'
        str << encode(c,c.text)
      else
        str << encode(c,@var[c.name])
      end
      @v.msg("CMD:GetFrame:#{c.attributes['label']} [#{str}]")
    }
    str
  end

  # Common Method
  def checkcode(e,str)
    chk=0
    if method=e.attributes['method']
      case method
      when 'len'
        chk=str.length
      when 'bcc'
        str.each_byte {|c| chk ^= c }
      else
        @v.err "No such CC method #{method}"
      end
      @v.msg("Calc:CC [#{ method.upcase}] -> [#{chk}]")
      return chk
    end
    @v.err "CC No method"
  end

  Pack={'hex'=>'H*','chr'=>'C','bew'=>'n','lew'=>'v'}

  def decode(e,code)
    if upk=Pack[e.attributes['unpack']]
      str=code.unpack(upk).first
      @v.msg("Decode:unpack(#{upk}) [#{code}] -> [#{str}]")
      code=str
    end
    format(e,code)
  end

  def encode(e,str)
    if pack=Pack[e.attributes['pack']]
      str=str.to_i if pack != 'H*'
      code=[str].pack(pack)
      @v.msg("Encode:pack(#{pack}) [#{str}] -> [#{code}]")
      str=code
    end
    format(e,str)
  end

  def format(e,code)
    if fmt=e.attributes['format']
      str=fmt % code
      $ver.msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]")
      code=str
    end
    code.to_s
  end

end
