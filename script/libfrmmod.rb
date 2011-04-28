#!/usr/bin/ruby
module FrmMod
  # Instance variable: @v

  def checkcode(method,frame)
    @v.err("CC No method") unless method
    @v.msg{"CC Frame <#{frame}>"}
    chk=0
    case method
    when 'len'
      chk=frame.length
    when 'bcc'
      frame.each_byte {|c| chk ^= c }
    when 'sum'
      frame.each_byte {|c| chk += c }
      chk%=256
    else
      @v.err("No such CC method #{method}")
    end
    @v.msg{"Calc:CC [#{method.upcase}] -> (#{chk})"}
    return chk.to_s
  end

  Codec={'hexstr'=>'hex','chr'=>'C','bew'=>'n','lew'=>'v'}

  def decode(e,code) # Chr -> Num
    cdc=e['decode']
    if upk=Codec[cdc]
      num=(upk == 'hex') ? code.hex : code.unpack(upk).first
      @v.msg{"Decode:(#{cdc}) [#{code}] -> [#{num}]"}
      code=num
    end
    return code.to_s
  end

  def encode(e,str) # Num -> Chr
    cdc=e['encode']
    if pck=Codec[cdc]
      code=[eval(str)].pack(pck)
      @v.msg{"Encode:(#{cdc}) [#{str}] -> [#{code}]"}
      str=code
    end
    if fmt=e['format']
      @v.msg{"Formatted code(#{fmt}) [#{str}]"}
      code=fmt % eval(str)
      @v.msg{"Formatted code(#{fmt}) [#{str}] -> [#{code}]"}
      str=code
    end
    str.to_s
  end

  #Initialize
  def init_main(doc,domain,hash)
    begin
      @v.msg(1){"Start Main Frame"}
      frame=[]
      doc[domain].each{|e1|
        frame << init_element(e1)
      }
      @v.msg{"InitMainFrame:[#{frame}]"}
      hash.update(doc[domain].to_h)
      hash['main']=frame.freeze
    ensure
      @v.msg(-1){"End Main Frame"}
    end
  end

  def init_cc(doc,domain,hash)
    doc.find_each(domain,'ccrange'){|e0|
      begin
        @v.msg(1){"Start Ceck Code Frame"}
        frame=[]
        e0.each{|e1|
          frame << init_element(e1)
        }
        @v.msg{"InitCCFrame:[#{frame}]"}
        hash[:method]=e0['method']
        hash['ccrange']=frame.freeze
      ensure
        @v.msg(-1){"End Ceck Code Frame"}
      end
    }
  end

  def init_sel(doc,domain,select)
    list={}
    doc.find_each(domain,select){|e0|
      begin
        @v.msg(1){"Start Select Frame"}
        frame=[]
        e0.each{|e1|
          frame << init_element(e1)
        }
        selh=e0.to_h
        id=selh.delete('id')
        selh[:frame] = frame.freeze
        @v.msg{"InitSelFrame:[#{frame}]"}
        list[id]=selh
      ensure
        @v.msg(-1){"End Select Frame"}
      end
    }
    list
  end

  def mk_db(db,name)
    hash={}
    db.each{|k,v|
      hash[k]=v[name]
    }
    hash
  end
end
