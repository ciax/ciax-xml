#!/usr/bin/ruby
require "librepeat"
require "libdb"

module Frm
  class Db < Db
    def initialize
      super('fdb')
    end

    def set(id=nil)
      super{|doc|
        hash={}
        hash.update(doc)
        hash['id']=hash.delete('id')
        rfm=hash[:field]={}
        dc=doc.domain('cmdframe')
        dr=doc.domain('rspframe')
        hash[:cmdframe]=init_main(dc){|e,r| init_cmd(e,r)}
        hash[:rspframe]=init_main(dr){|e| init_rsp(e,rfm)}
        hash[:command]=init_sel(dc,'command'){|e,r| init_cmd(e,r)}
        hash[:response]=init_sel(dr,'response'){|e| init_rsp(e,rfm)}
        hash
      }
    end

    private
    def init_main(domain)
      hash=domain.to_h
      begin
        verbose(1){"INIT:Main Frame <-"}
        frame=[]
        domain.each{|e1|
          frame << yield(e1)
        }
        verbose{"InitMainFrame:#{frame}"}
        hash[:main]=frame
      ensure
        verbose(-1){"-> INIT:Main Frame"}
      end
      domain.find('ccrange'){|e0|
        begin
          verbose(1){"INIT:Ceck Code Frame <-"}
          frame=[]
          Repeat.new.each(e0){|e1,r1|
            frame << yield(e1,r1)
          }
          verbose{"InitCCFrame:#{frame}"}
          hash[:ccrange]=frame
        ensure
          verbose(-1){"-> INIT:Ceck Code Frame"}
        end
      }
      hash
    end

    def init_sel(domain,select)
      selh=domain.to_h
      domain.find(select){|e0|
        begin
          verbose(1){"INIT:Select Frame <-"}
          id=e0.attr2db(selh)
          (selh[:select]||={})[id]||=[]
          verbose{"InitSelHash(#{id})"}
          Repeat.new.each(e0){|e1,r1|
            set_par(e1,id,selh) && next
            e=yield(e1,r1) || next
            selh[:select][id] << e
          }
          verbose{"InitSelFrame(#{id})"}
        ensure
          verbose(-1){"-> INIT:Select Frame"}
        end
      }
      selh
    end

    def init_cmd(e,rep=nil)
      case e.name
      when 'char','string'
        attr=e.to_h
        attr['val']=rep.subst(attr['val']) if rep
        verbose{"Data:[#{attr}]"}
        attr
      else
        e.name
      end
    end

    def init_rsp(e,val)
      val[:select]||=ExHash.new
      case e.name
      when 'field'
        attr=e.to_h
        if id=attr['assign']
          val[:select][id]=nil
          add_label(val,attr,id)
        end
        verbose{"InitElement: #{attr}"}
        attr
      when 'array'
        attr=e.to_h
        idx=attr[:index]=[]
        e.each{|e1|
          idx << e1.to_h
        }
        id=attr['assign']
        val[:select][id]=init_array(idx.map{|h| h['size']})
        add_label(val,attr,id)
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

    def add_label(val,attr,id)
      if lv=attr['label']
        (val[:label]||={})[id]=lv
        verbose{"LABEL:[#{id}] : #{lv}"}
      end
    end
  end
end

if __FILE__ == $0
  begin
    fdb=Frm::Db.new.set(ARGV.shift)
  rescue InvalidID
    warn "USAGE: #{$0} [id] (key) .."
    Msg.exit
  end
  puts fdb.path(ARGV)
end

