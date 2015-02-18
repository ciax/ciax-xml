#!/usr/bin/ruby
require "libfrmdb"

module CIAX
  module Dev
    class Db < Db
      def initialize
        super('ddb')
      end

      def set(id=nil)
        cpy=super
        cpy.cover(Frm::Db.new.set(cpy['frm_id']))
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

    if __FILE__ == $0
      begin
        id=ARGV.shift
        db=Db.new.set(id)
      rescue
        Msg.usage("(opt) [id] (key) ..")
        Msg.exit
      end
      puts db.path(ARGV)
    end
  end
end
