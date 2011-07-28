#!/usr/bin/ruby
require "librepeat"
require "libdb"

class FrmDb < Db
  attr_reader :frame
  def initialize(frm)
    super('fdb',frm)
    @rep=Repeat.new
    @frame={}
    domc=@doc.domain('cmdframe')
    domr=@doc.domain('rspframe')
    @frame[:command]=init_main(domc){|e| init_cmd(e)}
    @frame[:status]=init_main(domr){|e| init_stat(e)}
    @v.msg{"Structure:frame:#{@frame}"}
    @command.update(init_sel(domc,'command'){|e| init_cmd(e)})
    @v.msg{"Structure:command:#{@command}"}
    @status.update(init_sel(domr,'response'){|e| init_stat(e)})
    @v.msg{"Structure:status:#{@status}"}
  end

  def to_s
    super+Verbose.view_struct("Frame",@frame)
  end

  private
  def init_main(domain)
    hash=domain.to_h
    begin
      @v.msg(1){"INIT:Main Frame <-"}
      frame=[]
      domain.each{|e1|
        frame << yield(e1)
      }
      @v.msg{"InitMainFrame:#{frame}"}
      hash[:main]=frame.freeze
    ensure
      @v.msg(-1){"-> INIT:Main Frame"}
    end
    domain.each('ccrange'){|e0|
      begin
        @v.msg(1){"INIT:Ceck Code Frame <-"}
        frame=[]
        @rep.each(e0){|e1|
          frame << yield(e1)
        }
        @v.msg{"InitCCFrame:#{frame}"}
        hash[:ccrange]=frame.freeze
      ensure
        @v.msg(-1){"-> INIT:Ceck Code Frame"}
      end
    }
    hash
  end

  def init_sel(domain,select)
    selh={}
    list=selh[:select]={}
    domain.each(select){|e0|
      begin
        @v.msg(1){"INIT:Select Frame <-"}
        id=e0.attr2db(selh)
        @v.msg{"InitSelHash(#{id}):#{selh}"}
        frame=[]
        @rep.each(e0){|e1|
          e=yield(e1) || next
          frame << e
        }
        list[id]=frame.freeze 
        @v.msg{"InitSelFrame(#{id}):#{frame}"}
      ensure
        @v.msg(-1){"-> INIT:Select Frame"}
      end
    }
    selh
  end

  def init_cmd(e)
    case e.name
    when 'code','string'
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
        [:symbol,:label,:arrange].each{|k|
          @status[k]={} unless @status.key?(k)
          if d=attr.delete(k.to_s)
            @status[k][id]=d
            @v.msg{k.to_s.upcase+":[#{id}] : #{d}"}
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

if __FILE__ == $0
  db=FrmDb.new(ARGV.shift) rescue ("USAGE: #{$0} [id]\n#{$!}")
  puts db
end
