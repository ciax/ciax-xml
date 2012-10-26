#!/usr/bin/ruby
require "libappdb"
require "libfrmdb"

module Loc
  class Db < Db
    def initialize(id)
      super('ldb',id){|doc| rec_db(doc.top)}
      cover(App::Db.new(self['app_type']),:app)
      app=self[:app]
      frm=self[:frm]||{}
      if ref=frm['ref']
        frm.replace(Db.new(ref)[:frm])
        frm['id']=ref
      else
        frm=cover(Frm::Db.new(app['frm_type']),:frm)
      end
      frm['host']||=(app['host']||='localhost')
      frm['port']||=app['port'].to_i-1000
      app['id']=id
      frm['id']||=id
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
