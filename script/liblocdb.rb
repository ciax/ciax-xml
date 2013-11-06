#!/usr/bin/ruby
require "libappdb"
require "libfrmdb"
require "libinsdb"

module CIAX
  module Loc
    class Db < Db
      def initialize
        super('ldb')
      end

      def set(id=nil)
        super
        appid=delete('app_id')
        insid=delete('ins_id')||self['id']
        cover(App::Db.new.set(appid),:app).ext_ins(insid)
        app=self[:app].update({'ins_id'=>insid,'site_id'=>id})
        frm=self[:frm]||{}
        if ref=frm.delete('ref')
          frm=cover(Db.new.set(ref)[:frm],:frm)
        else
          frm=cover(Frm::Db.new.set(app.delete('frm_id')),:frm)
          frm['site_id']||=id
        end
        frm['host']||=(app['host']||='localhost')
        frm['port']||=app['port'].to_i-1000
        app['id']=app.delete('app_id')
        self
      end

      private
      def doc_to_db(doc)
        rec_db(doc.top)
      end

      def rec_db(e0,hash={})
        (hash||={}).update(e0.to_h)
        e0.each{|e|
          if e['id']
            e.attr2item(hash)
          else
            id=e.name.to_sym
            verbose("LocDb","Override [#{id}]")
            rec_db(e,hash[id]||={})
          end
        }
        hash
      end
    end
  end

  if __FILE__ == $0
    begin
      id=ARGV.shift
      db=Loc::Db.new.set(id)
    rescue
      Msg.usage("(opt) [id] (key) ..")
      Msg.exit
    end
    puts db.path(ARGV)
  end
end
