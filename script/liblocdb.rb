#!/usr/bin/ruby
require "libappdb"
require "libfrmdb"

module Loc
  class Db < Db
    def initialize(id)
      self['id']=id
      super('ldb',id){|doc|
        hash={}
        hash.update(doc)
        doc.top.each{|e0|
          case e0.name
          when 'app'
            hash[:app]=App::Db.new(hash['app_type'])
            rec_db(e0,hash[:app])
          when 'frm'
            hash[:frm]=Frm::Db.new(hash[:app]['frm_type'])
            rec_db(e0,hash[:frm])
          end
        }
        hash
      }
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
    id=ARGV.shift
    db=Loc::Db.new(id)
  rescue
    Msg.usage("(opt) [id] (key) ..")
    Msg.exit
  end
  puts db.path(ARGV)
end
