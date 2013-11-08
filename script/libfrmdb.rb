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
        hash=Hash[doc]
        # Command section
        members={}
        hcmd=hash[:command]={:group => {'main' => {'caption' => 'Main',:members => members}}}
        hcmd[:frame]=init_frame(doc.domain('cmdframe')){|e,r| init_cmd(e,r)}
        icmd=hcmd[:index]=init_index(doc.domain('commands')){|e,r| init_cmd(e,r)}
        icmd.each{|id,hash| members[id]=hash.delete('label')}
        # Status section
        hres=hash[:response]={}
        rfm=hash[:field]={}
        hres[:frame]=init_frame(doc.domain('rspframe')){|e| init_rsp(e,rfm)}
        hres[:index]=init_index(doc.domain('responses')){|e| init_rsp(e,rfm)}
        hash
      end

      def init_frame(domain)
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

      def init_index(domain)
        hash={}
        domain.each{|e0|
          enclose("Fdb","INIT:Body Frame <-","-> INIT:Body Frame"){
            id=e0.attr2item(hash)
            item=hash[id]
            Repeat.new.each(e0){|e1,r1|
              par2item(e1,item) && next
              e=yield(e1,r1) || next
              (item[:body]||=[]) << e
            }
          }
        }
        hash
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

      def init_rsp(e,field)
        if id=e['assign']
          item=field[id]={'label' => e['label']}
        end
        case e.name
        when 'field'
          attr=e.to_h
          item[:struct]=[] if item
          verbose("Fdb","InitElement: #{attr}")
          attr
        when 'array'
          attr=e.to_h
          idx=attr[:index]=[]
          e.each{|e1|
            idx << e1.to_h
          }
          item[:struct]=idx.map{|h| h['size']} if item
          attr
        when 'ccrange','body'
          e.name
        else
          nil
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
