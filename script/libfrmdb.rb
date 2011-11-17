#!/usr/bin/ruby
require "librepeat"
require "libdb"

class FrmDb < Db
  def initialize(frm,nocache=nil)
    super('fdb')
    cache(frm,nocache){|doc|
      update(doc)
      delete('id')
      cmd=self[:cmdframe]={}
      rsp=self[:rspframe]={:assign => {}}
      dc=doc.domain('cmdframe')
      dr=doc.domain('rspframe')
      fc=cmd[:frame]=init_main(dc){|e,r| init_cmd(e,r)}
      fr=rsp[:frame]=init_main(dr){|e| init_rsp(e,rsp)}
      cmd.update(init_sel(dc,'command',fc){|e,r| init_cmd(e,r)})
      rsp.update(init_sel(dr,'response',fr){|e| init_rsp(e,rsp)})
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
    domain.find(select){|e0|
      begin
        @v.msg(1){"INIT:Select Frame <-"}
        id=e0.attr2db(selh)
        (selh[:select]||={})[id]||=[]
        @v.msg{"InitSelHash(#{id})"}
        Repeat.new.each(e0){|e1,r1|
          case e1.name
          when 'par'
            ((selh[:parameter]||={})[id]||=[]) << e1.text
          else
            e=yield(e1,r1)||next
            selh[:select][id] << e
          end
        }
        @v.msg{"InitSelFrame(#{id})"}
      ensure
        @v.msg(-1){"-> INIT:Select Frame"}
      end
    }
    selh
  end

  def init_cmd(e,rep=nil)
    case e.name
    when 'char','string'
      attr=e.to_h
      attr['val']=rep.subst(attr['val']) if rep
      @v.msg{"Data:[#{attr}]"}
      attr
    else
      e.name
    end
  end

  def init_rsp(e,stat)
    case e.name
    when 'field'
      attr=e.to_h
      if id=attr['assign']
        stat[:assign][id]=nil
        stat[:label]||={}
        if lv=attr['label']
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
      stat[:assign][attr['assign']]=init_array(idx.map{|h| h['size']})
      attr
    when 'ccrange','select'
      e.name
    else
      nil
    end
  end

  def init_array(sary,field=nil)
    return if sary.empty?
    a=field||[]
    sary[0].to_i.times{|i|
      a[i]=init_array(sary[1..-1],a[i])
    }
    a
  end
end

if __FILE__ == $0
  begin
    fdb=FrmDb.new(ARGV.shift,true)
  rescue SelectID
    warn "USAGE: #{$0} [id] (key) .."
    Msg.exit
  end
  puts fdb.path(ARGV)
end

