#!/usr/bin/ruby
require "libappdb"
require "libfrmdb"
require "libinsdb"

module CIAX
  module Site
    class Db < Db
      def initialize
        super('ldb')
      end

      def set(id=nil)
        ldb=super
        appid=ldb.delete('app_id')
        insid=ldb.delete('ins_id')||ldb['id']
        ldb.cover(App::Db.new.set(appid),:adb).ext_ins(insid)
        app=ldb[:adb].update({'ins_id'=>insid,'site_id'=>id})
        frm=ldb[:fdb]||{}
        if ref=frm.delete('ref')
          frm=ldb.cover(Db.new.set(ref)[:fdb],:fdb)
        else
          frm=ldb.cover(Frm::Db.new.set(app.delete('frm_id')),:fdb)
          frm['site_id']||=id
        end
        frm['host']||=(app['host']||='localhost')
        frm['port']||=app['port'].to_i-1000
        app['id']=app.delete('app_id')
        ldb
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
            verbose("SiteDb","Override [#{id}]")
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
      db=Site::Db.new.set(id)
    rescue
      Msg.usage("(opt) [id] (key) ..")
      Msg.exit
    end
    puts db.path(ARGV)
  end
end
