#!/usr/bin/ruby
require "libfrmdb"

module CIAX
  module Dev;Color=2
    class Db < Db
      def initialize(proj=PROJ)
        super('ddb',proj)
      end

      def get(id=nil)
        cpy=super
        cpy.cover(Frm::Db.new.get(cpy['frm_id']))
      end

      private
      def doc_to_db(doc)
        db=rec_db(doc[:top])
        db['proj']=@proj
        db['site_id']=db['id']
        db
      end

      def rec_db(e0,hash=Dbi.new)
        (hash||=Dbi.new).update(e0.to_h)
        e0.each{|e|
          if e['id']
            e.attr2item(hash)
          else
            id=e.name.to_sym
            verbose("Override [#{id}]")
            rec_db(e,hash[id]||={})
          end
        }
        hash
      end
    end

    if __FILE__ == $0
      begin
        db=Db.new(ARGV.shift).get(ARGV.shift)
      rescue
        Msg.usage("(opt) [id] (key) ..")
        Msg.exit
      end
      puts db.path(ARGV)
    end
  end
end
