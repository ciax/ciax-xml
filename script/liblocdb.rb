#!/usr/bin/ruby
require "libappdb"
require "libfrmdb"
require "libinsdb"

module Loc
  class Db < Db
    def initialize(id=nil)
      super('ldb',id){|doc| rec_db(doc.top)}
      appid=delete('app_id')
      insid=delete('ins_id')||self['id']
      cover(App::Db.new(appid),:app).ext_ins(insid)
      app=self[:app].update({'id'=>appid,'ins_id'=>insid,'site_id'=>id})
      frm=self[:frm]||{}
      if ref=frm.delete('ref')
        frm=cover(Db.new(ref)[:frm],:frm)
      else
        frm=cover(Frm::Db.new(app.delete('frm_id')),:frm)
        frm['site_id']||=id
      end
      frm['host']||=(app['host']||='localhost')
      frm['port']||=app['port'].to_i-1000
    end

    private
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
    db=Loc::Db.new(id)
  rescue
    Msg.usage("(opt) [id] (key) ..")
    Msg.exit
  end
  puts db.path(ARGV)
end
