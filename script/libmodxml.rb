#!/usr/bin/ruby
# XML Common Method
module ModXml
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

  def validate(e,str)
    @v.err("No Parameter") unless str
    @v.msg("Validate String [#{str}]")
    case e.attributes['validate']
    when 'regexp'
      @v.err("Parameter invalid(#{e.text})") if /^#{e.text}$/ !~ str
    when 'range'
      e.text.split(',').any? { |s|
        NumRange.new(s) == str
      } || @v.err("Parameter out of range(#{e.text})")
    end
    str
  end

  def format(e,code)
    if fmt=e.attributes['format']
      str=fmt % code
      @v.msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]")
      code=str
    end
    code.to_s
  end

  def list_id(e)
    e.each_element {|d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}" if a['label']
      true
    } && raise("No such ID")
  end

end
