#!/usr/bin/ruby
require "libdb"

module Loc
  class Db < Db
    def initialize(id)
      self['id']=id
      super('ldb',id){|doc|
        hash={}
        hash.update(doc)
        rec_db(doc.top,hash)
        hash
      }
    end

    # overwrite App::Db
    def cover_app
      require "libappdb"
      cover(App::Db.new(self[:app]['type']),:app)
    end

    def cover_frm
      require "libappdb"
      require "libfrmdb"
      frm=App::Db.new(self[:app]['type'])['frm_type']
      cover(Frm::Db.new(frm),:frm)
    end

    private
    def rec_db(e,hash={})
      e.each{|e0|
        if e0.name == 'field'
          (hash[:assign]||={})[e0['assign']]=e0.text
        else
          crnt=hash[e0.name.to_sym]=e0.to_h
          crnt['val']=e0.text if e0.text
          rec_db(e0,crnt)
        end
      }
    end
  end
end

if __FILE__ == $0
  begin
    Msg.getopts("af")
    id=ARGV.shift
    db=Loc::Db.new(id)
  rescue
    Msg.usage("(opt) [id] (key) ..",*$optlist)
    Msg.exit
  end
  if $opt["a"]
    db=db.cover_app
  elsif $opt["f"]
    db=db.cover_frm
  end
  puts db.path(ARGV)
end
