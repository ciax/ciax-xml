#!/usr/bin/ruby
require "librepeat"
require "libdbcache"

class FrmDb < DbCache
  def initialize(frm)
    super('fdb',frm)
    self[:frame].freeze
  end

  def refresh
    update(doc)
    frame=self[:frame]={}
    self[:status]={}
    domc=doc.domain('cmdframe')
    domr=doc.domain('rspframe')
    frame[:command]=init_main(domc){|e,r| init_cmd(e,r)}
    frame[:status]=init_main(domr){|e| init_stat(e)}
    @v.msg{"Structure:frame:#{self[:frame]}"}
    init_sel(domc,'command',:command){|e,r| init_cmd(e,r)}
    @v.msg{"Structure:command:#{self[:command]}"}
    init_sel(domr,'response',:status){|e| init_stat(e)}
    @v.msg{"Structure:status:#{self[:status]}"}
    save
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

  def init_sel(domain,select,key)
    selh=self[key]=domain.to_h
    list=self[:frame][key][:select]={}
    domain.each(select){|e0|
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
    self
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

  def init_stat(e)
    case e.name
    when 'field'
      attr=e.node2db
      if id=attr['assign']
        [:symbol,:label,:arrange].each{|k|
          self[:status][k]={} unless self[:status].key?(k)
          if d=attr.delete(k.to_s)
            self[:status][k][id]=d
            @v.msg{k.to_s.upcase+":[#{id}] : #{d}"}
          end
        }
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
    db=FrmDb.new(ARGV.shift).refresh
  rescue SelectID
    abort("USAGE: #{$0} [id]\n#{$!}")
  end
  puts db
end
