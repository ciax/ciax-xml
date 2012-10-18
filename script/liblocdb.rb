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
      cover(App::Db.new(self['app_type']),:app)
      self[:app]['host']||='localhost'
      self
    end

    def cover_frm
      frm=self[:frm]||{}
      if ref=frm['ref']
        self[:frm]=Db.new(ref).cover_app.cover_frm[:frm]
      else
        cover(Frm::Db.new(self[:app]['frm_type']),:frm)
      end
      self[:frm]['host']||=self[:app]['host']
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
