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
        id=ldb['site_id']=ldb.delete('id')
        insid=ldb['ins_id']||id
        ldb.cover(Ins::Db.new.set(insid).cover_app,:adb)
        # For App
        app=ldb[:adb].update('site_id'=>id)
        ldb['app_site']=id
        # For Frm
        frm=ldb[:fdb]||{}
        if ref=frm.delete('ref')
          warn "FRM FEF ID =#{ref}"#
          frm=ldb.cover(Db.new.set(ref)[:fdb],:fdb)
          id=ref
        else
          frm=ldb.cover(Frm::Db.new.set(app['frm_id']),:fdb)
        end
        ldb['frm_site']=id
        frm['site_id']=id
        frm['host']||=(app['host']||='localhost')
        frm['port']||=app['port'].to_i-1000
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
