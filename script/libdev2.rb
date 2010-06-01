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
    i=0
    session.each_element {|io|
      @sel=io
      case io.name
      when 'send'
        print sndstr=cmdframe
#        @ic.snd(sndstr,['snd',i,cmd,par])
      when 'recv'
        rcvstr=gets(nil)
#        rcvstr=@ic.rcv(['rcv',i,cmd])
#        @stat['time']="%.3f" % @ic.time.to_f
        rspframe(rcvstr)
      end
      i+=1
    }
    @stat
  end

  # Rsp Methods
  def rspframe(frame)
    @v.err("RSP:No String") unless frame
    @frame=frame
    getstat(@doc.elements['//rspframe'])
    if @stat['cc']
      if @stat['cc'] === @var[:cc]
        @v.msg("RSP:Verify:CC OK")
      else
        @v.err("RSP:Verifu:CC Mismatch[#{@stat['cc']}]!=[#{@var[:cc]}]") 
      end
      @stat.delete('cc')
    end
  end

  def getstat(e)
    frame=String.new
    e.each_element { |c|
      case c.name
      when 'ccrange'
        @v.msg("RSP:Entering Ceck Code Node")
        @var[:cc] = checkcode(c,getstat(c))
      when 'select'
        @v.msg("RSP:Entering Selected Node")
        frame << getstat(@sel)
      when 'verify'
        @v.msg("RSP:Verify:#{c.attributes['label']}[#{c.text}]")
        frame << s=cut_frame(c)
        @v.err("RSP:Verify Mismatch") if c.text != decode(c,s)
      when 'cc_rsp'
        @v.msg("RSP:Store:#{c.attributes['label']}")
        frame << s=cut_frame(c)
        @stat['cc']=decode(c,s)
      when 'assign'
        @v.msg("RSP:Assign:#{c.attributes['label']}")
        frame << s=cut_frame(c)
        @stat[c.text]=decode(c,s)
      when 'repeat_assign'
        min=c.attributes['min']||0
        max=c.attributes['max']
        (min.to_i .. max.to_i).each { |n|
          @v.msg("RSP:Repeat Assign:#{c.attributes['label']}(#{n})]")
          frame << s=cut_frame(c)
          @stat[c.text % n]=decode(c,s)
        }
      when 'rspcode'
        frame << s=cut_frame(c)
        label="ResponseCode:#{c.attributes['label']}:"
        str=decode(c,s)
        c.each_element {|g| #Match each case
          next if g.text && g.text != str
          msg=label+g.attributes['msg']+" [#{str}]"
          case g.attributes['type']
          when 'pass'
            @v.msg(msg)
          when 'warn'
            @v.wrn(msg)
          when 'error'
            @v.err(msg)
          end
          @sel=@doc.select_id('//session/recv',a) if a=e.attributes['option']
          break
        }
#        @v.wrn(label+":Unknown code [#{str}]")
      end
    }
    frame
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

  # Common Method
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
      @v.msg("Calc:CC [#{ method.upcase}] -> [#{chk}]")
      return chk.to_s
    end
    @v.err "CC No method"
  end

  Pack={'hexstr'=>'hex','hex'=>'H*','chr'=>'C','bew'=>'n','lew'=>'v'}

  def decode(e,code)
    if upk=Pack[e.attributes['unpack']]
      str=(upk == 'hex') ? code.hex : code.unpack(upk).first
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
      @v.msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]")
      code=str
    end
    code.to_s
  end

end
