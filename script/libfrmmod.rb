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

  #Initialize
  def init_main(doc,domain)
    hash={}
    begin
      @v.msg(1){"INIT:Main Frame <-"}
      frame=[]
      doc[domain].each{|e1|
        frame << init_element(e1)
      }
      @v.msg{"InitMainFrame:#{frame}"}
      hash.update(doc[domain].to_h)
      hash['main']=frame.freeze
    ensure
      @v.msg(-1){"-> INIT:Main Frame"}
    end
    doc.find_each(domain,'ccrange'){|e0|
      begin
        @v.msg(1){"INIT:Ceck Code Frame <-"}
        frame=[]
        e0.each{|e1|
          frame << init_element(e1)
        }
        @v.msg{"InitCCFrame:#{frame}"}
        hash[:method]=e0['method']
        hash['ccrange']=frame.freeze
      ensure
        @v.msg(-1){"-> INIT:Ceck Code Frame"}
      end
    }
    hash
  end

  def init_sel(doc,domain,select)
    list={}
    doc.find_each(domain,select){|e0|
      begin
        @v.msg(1){"INIT:Select Frame <-"}
        selh=e0.to_h
        id=selh.delete('id')
        @v.msg{"InitSelHash(#{id}):#{selh}"}
        frame=[]
        e0.each{|e1|
          e=init_element(e1) || next
          frame << e
        }
        unless frame.empty?
          selh[:frame] = frame.freeze 
          @v.msg{"InitSelFrame(#{id}):#{frame}"}
        end
        list[id]=selh
      ensure
        @v.msg(-1){"-> INIT:Select Frame"}
      end
    }
    list
  end
end
