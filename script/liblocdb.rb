#!/usr/bin/ruby
require "libappdb"
require "libfrmdb"
require "libinsdb"

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
      app=self[:app].update({'id'=>appid,'ins_id'=>insid,'site_id'=>id})
      frm=self[:frm]||{}
      if ref=frm.delete('ref')
        frm=cover(Db.new.set(ref)[:frm],:frm)
      else
        frm=cover(Frm::Db.new.set(app.delete('frm_id')),:frm)
        frm['site_id']||=id
      end
      frm['host']||=(app['host']||='localhost')
      frm['port']||=app['port'].to_i-1000
      self
    end

    private
    def doc_to_db(doc)
      rec_db(doc.top)
    end

    def rec_db(e0,hash={})
      (hash||={}).update(e0.to_h)
      e0.each{|e|
        key=e.name.to_sym
        if key == :field
          (hash[:assign]||={})[e['assign']]=e.text
        else
          hash['val']=e.text if e.text
          rec_db(e,hash[key]||={})
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
