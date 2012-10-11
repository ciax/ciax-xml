#!/usr/bin/ruby
require "librepeat"
require "libdb"

module Frm
  class Db < Db
    extend Msg::Ver
    def initialize(id)
      Db.init_ver('fdb')
      super('fdb',id){|doc|
        hash={}
        hash.update(doc)
        hash.delete('id')
        hash['frm_ver']=hash.delete('version')
        hash['frm_label']=hash.delete('label')
        cmd=hash[:cmdframe]={}
        rsp=hash[:rspframe]={:assign => {}}
        dc=doc.domain('cmdframe')
        dr=doc.domain('rspframe')
        fc=cmd[:frame]=init_main(dc){|e,r| init_cmd(e,r)}
        fr=rsp[:frame]=init_main(dr){|e| init_rsp(e,rsp)}
        cmd.update(init_sel(dc,'command',fc){|e,r| init_cmd(e,r)})
        rsp.update(init_sel(dr,'response',fr){|e| init_rsp(e,rsp)})
        hash
      }
    end

    private
    def init_main(domain)
      hash=domain.to_h
      begin
        Db.msg(1){"INIT:Main Frame <-"}
        frame=[]
        domain.each{|e1|
          frame << yield(e1)
        }
        Db.msg{"InitMainFrame:#{frame}"}
        hash[:main]=frame
      ensure
        Db.msg(-1){"-> INIT:Main Frame"}
      end
      domain.find('ccrange'){|e0|
        begin
          Db.msg(1){"INIT:Ceck Code Frame <-"}
          frame=[]
          Repeat.new.each(e0){|e1,r1|
            frame << yield(e1,r1)
          }
          Db.msg{"InitCCFrame:#{frame}"}
          hash[:ccrange]=frame
        ensure
          Db.msg(-1){"-> INIT:Ceck Code Frame"}
        end
      }
      hash
    end

    def init_sel(domain,select,frame)
      selh=domain.to_h
      domain.find(select){|e0|
        begin
          Db.msg(1){"INIT:Select Frame <-"}
          id=e0.attr2db(selh)
          (selh[:select]||={})[id]||=[]
          Db.msg{"InitSelHash(#{id})"}
          Repeat.new.each(e0){|e1,r1|
            set_par(e1,id,selh) && next
            e=yield(e1,r1) || next
            selh[:select][id] << e
          }
          Db.msg{"InitSelFrame(#{id})"}
        ensure
          Db.msg(-1){"-> INIT:Select Frame"}
        end
      }
      selh
    end

    def init_cmd(e,rep=nil)
      case e.name
      when 'char','string'
        attr=e.to_h
        attr['val']=rep.subst(attr['val']) if rep
        Db.msg{"Data:[#{attr}]"}
        attr
      else
        e.name
      end
    end

    def init_rsp(e,val)
      case e.name
      when 'field'
        attr=e.to_h
        if id=attr['assign']
          val[:assign][id]=nil
          val[:label]||={}
          if lv=attr['label']
            val[:label][id]=lv
            Db.msg{"LABEL:[#{id}] : #{lv}"}
          end
        end
        Db.msg{"InitElement: #{attr}"}
        attr
      when 'array'
        attr=e.to_h
        idx=attr[:index]=[]
        e.each{|e1|
          idx << e1.to_h
        }
        val[:assign][attr['assign']]=init_array(idx.map{|h| h['size']})
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
end

if __FILE__ == $0
  begin
    fdb=Frm::Db.new(ARGV.shift)
  rescue InvalidID
    warn "USAGE: #{$0} [id] (key) .."
    Msg.exit
  end
  puts fdb.path(ARGV)
end

