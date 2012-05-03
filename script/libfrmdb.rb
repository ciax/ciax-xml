#!/usr/bin/ruby
require "librepeat"
require "libdb"

module Frm
  class Db < Db
    def initialize(frm)
      super('fdb')
      set(frm){|doc|
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

    def init_rsp(e,val)
      case e.name
      when 'field'
        attr=e.to_h
        if id=attr['assign']
          val[:assign][id]=nil
          val[:label]||={}
          if lv=attr['label']
            val[:label][id]=lv
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
  rescue SelectID
    warn "USAGE: #{$0} [id] (key) .."
    Msg.exit
  end
  puts fdb.path(ARGV)
end

