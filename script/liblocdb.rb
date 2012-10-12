#!/usr/bin/ruby
require "libappdb"
require "libfrmdb"

module Loc
  class Db < Db
    def initialize(id)
      super('ldb',id){|doc|
        hash=rec_db(doc.top)
        [:app,:frm].each{|k|
          hash[k]['id'] = id
        }
        hash
      }
    end

    def cover_app
      app=self[:app]||{}
      self[:app]=App::Db.new(self['app_type']).deep_update(app)
      self
    end

    def cover_frm
      frm=self[:frm]||{}
      self[:frm]=Frm::Db.new(self[:app]['frm_type']).deep_update(frm)
      self[:frm]['port']||=self[:app]['port'].to_i+1000
      self
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
    db=Loc::Db.new(id).cover_app.cover_frm
  rescue
    Msg.usage("(opt) [id] (key) ..")
    Msg.exit
  end
  puts db.path(ARGV)
end
