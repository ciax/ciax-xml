#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "librepeat"
require "libsymdb"

class FrmDb < Hash
  attr_reader :fdbc,:selc,:fdbs,:sels
  def initialize(frm)
    @doc=XmlDoc.new('fdb',frm)
    @v=Verbose.new("fdb/#{@doc['id']}",2)
    @rep=Repeat.new
    update(@doc)
    @fdbc=init_main('cmdframe'){|e| init_cmd(e)}
    @selc=init_sel('cmdframe','command'){|e| init_cmd(e)}
    @fdbs=init_main('rspframe'){|e| init_stat(e)}
    @sels=init_sel('rspframe','response'){|e| init_stat(e)}
    self[:symtbl]=SymDb.new(@doc)
  end

  def checkcode(frame)
    @v.msg{"CC Frame <#{frame}>"}
    chk=0
    case @method
    when 'len'
      chk=frame.length
    when 'bcc'
      frame.each_byte {|c| chk ^= c }
    when 'sum'
      frame.each_byte {|c| chk += c }
      chk%=256
    else
      @v.err("No such CC method #{@method}")
    end
    @v.msg{"Calc:CC [#{@method.upcase}] -> (#{chk})"}
    return chk.to_s
  end

  private
  def init_main(domain)
    hash=@doc.domain(domain).to_h
    begin
      @v.msg(1){"INIT:Main Frame <-"}
      frame=[]
      @doc.find_each(domain){|e1|
        frame << yield(e1)
      }
      @v.msg{"InitMainFrame:#{frame}"}
      hash['main']=frame.freeze
    ensure
      @v.msg(-1){"-> INIT:Main Frame"}
    end
    @doc.find_each(domain,'ccrange'){|e0|
      begin
        @v.msg(1){"INIT:Ceck Code Frame <-"}
        frame=[]
        @rep.each(e0){|e1|
          frame << yield(e1)
        }
        @v.msg{"InitCCFrame:#{frame}"}
        @method=e0['method']
        @v.err("CC No method") unless @method
        hash['ccrange']=frame.freeze
      ensure
        @v.msg(-1){"-> INIT:Ceck Code Frame"}
      end
    }
    hash
  end

  def init_sel(domain,select)
    list={}
    @doc.find_each(domain,select){|e0|
      begin
        @v.msg(1){"INIT:Select Frame <-"}
        selh=e0.to_h
        id=selh.delete('id')
        @v.msg{"InitSelHash(#{id}):#{selh}"}
        frame=[]
        @rep.each(e0){|e1|
          e=yield(e1) || next
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

  def init_cmd(e)
    case e.name
    when 'data'
      attr=e.to_h
      label=attr.delete('label')
      attr['val']=@rep.subst(e.text)
      @v.msg{"Data:#{label}[#{attr}]"}
      attr
    else
      e.name
    end
  end

  def init_stat(e)
    case e.name
    when 'field'
      attr=e.to_h
      attr['val']=e.text
      if id=attr['assign']
        [:symbol,:label,:group].each{|k|
          self[k]={} unless key?(k)
          if d=attr.delete(k.to_s)
            self[k][id]=d
            @v.msg{k.to_s.upcase+":[#{id}] : #{k}"}
          end
        }
      end
      @v.msg{"InitElement: #{attr}"}
      attr
    when 'array'
      attr=e.to_h
      id=attr['assign']
      idx=attr[:index]=[]
      e.each{|e1|
        idx << e1.to_h
      }
      init_array(idx.map{|h| h['size']}){'0'}
      attr
    when 'ccrange','select'
      e.name
    else
      nil
    end
  end
  
  def init_array(sary,field=nil)
    return yield if sary.empty?
    a=field||[]
    sary[0].to_i.times{|i|
      a[i]=init_array(sary[1..-1],a[i]){yield}
    }
    a
  end

end
