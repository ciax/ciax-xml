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
        dbi=Dbi[doc[:attr]]
        init_command(doc,dbi)
        init_stat(doc,dbi)
        dbi
      end

      # Command section
      def init_command(doc,dbi)
        frm=init_frame(doc[:domain]['cmdframe']){|e,r| init_cmd(e,r)}
        idx=init_index(doc[:domain]['command']){|e,r| init_cmd(e,r)}
        grp={'main' => {'caption' => 'Device Commands',:members => idx.keys}}
        dbi[:command]={:group => grp, :index => idx, :frame => frm}
        dbi
      end

      # Status section
      def init_stat(doc,dbi)
        dbi[:field]=fld={}
        frm=init_frame(doc[:domain]['rspframe']){|e| init_rsp(e,fld)}
        idx=init_index(doc[:domain]['responses']){|e| init_rsp(e,fld)}
        dbi['frm_id']=dbi['id']
        dbi[:response]={:index => idx, :frame => frm}
        dbi
      end

      def init_frame(domain)
        db=domain.to_h
        enclose("INIT:Main Frame <-","-> INIT:Main Frame"){
          frame=[]
          domain.each{|e1|
            frame << yield(e1)
          }
          verbose("InitMainFrame:#{frame}")
          db[:main]=frame
        }
        domain.find('ccrange'){|e0|
          enclose("INIT:Ceck Code Frame <-","-> INIT:Ceck Code Frame"){
            frame=[]
            Repeat.new.each(e0){|e1,r1|
              frame << yield(e1,r1)
            }
            verbose("InitCCFrame:#{frame}")
            db[:ccrange]=frame
          }
        }
        db
      end

      def init_index(domain)
        db={}
        domain.each{|e0|
          id=e0.attr2item(db)
          item=db[id]
          enclose("INIT:Body Frame [#{id}]<-","-> INIT:Body Frame"){
            Repeat.new.each(e0){|e1,r1|
              par2item(e1,item) && next
              e=yield(e1,r1) || next
              (item[:body]||=[]) << e
            }
          }
        }
        db
      end

      def init_cmd(e,rep=nil)
        case e.name
        when 'char','string'
          attr=e.to_h
          attr['val']=rep.subst(attr['val']) if rep
          verbose("Data:[#{attr}]")
          attr
        else
          e.name
        end
      end

      def init_rsp(e,field)
        # Avoid override duplicated id
        if (id=e['assign']) && !field.key?(id)
          item=field[id]={'label' => e['label']}
        end
        case e.name
        when 'field'
          attr=e.to_h
          item[:struct]=[] if item
          verbose("InitElement: #{attr}")
          attr
        when 'array'
          attr=e.to_h
          idx=attr[:index]=[]
          e.each{|e1|
            idx << e1.to_h
          }
          item[:struct]=idx.map{|h| h['size']} if item
          verbose("InitArray: #{attr}")
          attr
        when 'ccrange','body','echo'
          e.name
        else
          nil
        end
      end
    end

    if __FILE__ == $0
      begin
        dbi=Db.new.get(ARGV.shift)
      rescue InvalidID
        Msg.usage("[id] (key) ..")
      end
      puts dbi.path(ARGV)
      exit
    end
  end
end
