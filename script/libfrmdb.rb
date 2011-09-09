#!/usr/bin/ruby
require "librepeat"
require "libcache"

class FrmDb < Hash
  include Cache
  def initialize(frm,nocache=nil)
    @v=Msg::Ver.new('fdb',5)
    cache('fdb',frm,nocache){|doc|
      hash=Hash[doc]
      frame=hash[:frame]={}
      stat=hash[:status]={}
      cmd=hash[:command]={}
      dc=doc.domain('cmdframe')
      dr=doc.domain('rspframe')
      fc=frame[:command]=init_main(dc){|e,r| init_cmd(e,r)}
      fs=frame[:status]=init_main(dr){|e| init_stat(e,stat)}
      @v.msg{"Structure:frame:#{hash[:frame]}"}
      cmd.update(init_sel(dc,'command',fc){|e,r| init_cmd(e,r)})
      @v.msg{"Structure:command:#{hash[:command]}"}
      stat.update(init_sel(dr,'response',fs){|e| init_stat(e,stat)})
      @v.msg{"Structure:status:#{hash[:status]}"}
      hash
    }
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
    domain.find('ccrange'){|e0|
      begin
        @v.msg(1){"INIT:Ceck Code Frame <-"}
        frame=[]
        Repeat.new.each(e0){|e1,r1|
          frame << yield(e1,r1)
        }
        @v.msg{"InitCCFrame:#{frame}"}
        hash[:ccrange]=frame.freeze
      ensure
        @v.msg(-1){"-> INIT:Ceck Code Frame"}
      end
    }
    hash
  end

  def init_sel(domain,select,frame)
    selh=domain.to_h
    list=frame[:select]={}
    domain.find(select){|e0|
      begin
        @v.msg(1){"INIT:Select Frame <-"}
        id=e0.attr2db(selh)
        @v.msg{"InitSelHash(#{id}):#{selh}"}
        frame=[]
        Repeat.new.each(e0){|e1,r1|
          e=yield(e1,r1) || next
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

  def init_cmd(e,rep=nil)
    case e.name
    when 'code','string'
      attr=e.node2db
      label=attr.delete('label')
      attr['val']=rep.subst(attr['val']) if rep
      @v.msg{"Data:#{label}[#{attr}]"}
      attr
    else
      e.name
    end
  end

  def init_stat(e,stat)
    case e.name
    when 'field'
      attr=e.node2db
      if id=attr['assign']
        stat[:label]||={}
        if lv=attr.delete('label')
          stat[:label][id]=lv
          @v.msg{"LABEL:[#{id}] : #{lv}"}
        end
      end
      @v.msg{"InitElement: #{attr}"}
      attr
    when 'array'
      attr=e.to_h
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
  begin
    fdb=FrmDb.new(ARGV.shift,true)
  rescue SelectID
    abort("USAGE: #{$0} [id]\n#{$!}")
  end
  puts fdb
end
