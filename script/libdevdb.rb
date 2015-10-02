#!/usr/bin/ruby
require 'libfrmdb'

module CIAX
  module Dev; NsColor = 2
             class Db < Db
               def initialize(proj = PROJ)
                 super('ddb', proj)
               end
         
               def get(id = nil)
                 dbi = super
                 dbi.cover(Frm::Db.new.get(dbi['frm_id']))
               end
         
               private
               def doc_to_db(doc)
                 db = rec_db(doc[:top])
                 db['proj'] = @proj
                 db['site_id'] = db['id']
                 db
               end
         
               def rec_db(e0, dbi = Dbi.new)
                 (dbi ||= Dbi.new).update(e0.to_h)
                 e0.each{|e|
                   if e['id']
                     e.attr2item(dbi)
                   else
                     id = e.name.to_sym
                     verbose { "Override [#{id}]" }
                     rec_db(e, dbi[id] ||= {})
                   end
                 }
                 dbi
               end
             end

             if __FILE__ == $0
               begin
                 dbi = Db.new(ARGV.shift).get(ARGV.shift)
               rescue
                 Msg.usage('(opt) [id] (key) ..')
                 Msg.exit
               end
               puts dbi.path(ARGV)
             end
  end
end
