#!/usr/bin/ruby
require "librepeat"
require "libdb"

module CIAX
  module Frm
    class Db < Db
      def initialize
        super('fdb')
      end

      private
      def doc_to_db(doc)
        hash={}
        hash.update(doc)
        hash['id']=hash.delete('id')
        rfm=hash[:field]={}
        hash[:cmdframe]=init_main(doc.domain('cmdframe')){|e,r| init_cmd(e,r)}
        hash[:rspframe]=init_main(doc.domain('rspframe')){|e| init_rsp(e,rfm)}
        hash[:command]=init_sel(doc.domain('commands')){|e,r| init_cmd(e,r)}
        hash[:response]=init_sel(doc.domain('responses')){|e| init_rsp(e,rfm)}
        hash
      end

      def init_main(domain)
        hash=domain.to_h
        enclose("Fdb","INIT:Main Frame <-","-> INIT:Main Frame"){
          frame=[]
          domain.each{|e1|
            frame << yield(e1)
          }
          verbose("Fdb","InitMainFrame:#{frame}")
          hash[:main]=frame
        }
        domain.find('ccrange'){|e0|
          enclose("Fdb","INIT:Ceck Code Frame <-","-> INIT:Ceck Code Frame"){
            frame=[]
            Repeat.new.each(e0){|e1,r1|
              frame << yield(e1,r1)
            }
            verbose("Fdb","InitCCFrame:#{frame}")
            hash[:ccrange]=frame
          }
        }
        hash
      end

      def init_sel(domain)
        selh=domain.to_h
        domain.each{|e0|
          enclose("Fdb","INIT:Select Frame <-","-> INIT:Select Frame"){
            id=e0.attr2db(selh)
            (selh[:select]||={})[id]||=[]
            verbose("Fdb","InitSelHash(#{id})")
            Repeat.new.each(e0){|e1,r1|
              set_par(e1,id,selh) && next
              e=yield(e1,r1) || next
              selh[:select][id] << e
            }
            verbose("Fdb","InitSelFrame(#{id})")
          }
        }
        selh
      end

      def init_cmd(e,rep=nil)
        case e.name
        when 'char','string'
          attr=e.to_h
          attr['val']=rep.subst(attr['val']) if rep
          verbose("Fdb","Data:[#{attr}]")
          attr
        else
          e.name
        end
      end

      def init_rsp(e,val)
        stc=val[:struct]||=Hashx.new
        case e.name
        when 'field'
          attr=e.to_h
          if id=attr['assign']
            stc[id]=nil
            add_label(val,attr,id)
          end
          verbose("Fdb","InitElement: #{attr}")
          attr
        when 'array'
          attr=e.to_h
          idx=attr[:index]=[]
          e.each{|e1|
            idx << e1.to_h
          }
          id=attr['assign']
          stc[id]=init_array(idx.map{|h| h['size']})
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
          verbose("Fdb","LABEL:[#{id}] : #{lv}")
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
end
