#!/usr/bin/ruby
require "libappdb"
require "libfrmdb"

module Loc
  class Db < Db
    def initialize(id)
      super('ldb',id){|doc| rec_db(doc.top)}
      cover(App::Db.new(delete('app_type')),:app)
      app=self[:app]
      app['site']=id
      frm=self[:frm]||{}
      if ref=frm.delete('ref')
        frm=cover(Db.new(ref)[:frm],:frm)
      else
        frm=cover(Frm::Db.new(app.delete('frm_type')),:frm)
        frm['site']||=id
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
