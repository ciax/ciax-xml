#!/usr/bin/ruby
require 'libappdb'

module CIAX
  module Ins; NsColor = 6
             class Db < Db
               include Wat::Db
               def initialize(proj = PROJ)
                 super('idb', proj)
               end
         
               # overwrite App::Db
               def get(id = nil)
                 dbi = super
                 dbi.cover(App::Db.new.get(dbi['app_id']))
               end
         
               private
               def doc_to_db(doc)
                 dbi = Dbi[doc[:attr]]
                 # Command Domain
                 hcmd = dbi[:command] = {}
                 (doc[:domain]['alias'] || []).each{|e0|
                   e0.attr2item(hcmd[:alias] ||= {})
                   e0.each{|e1|
                     (hcmd[:alias][e0['id']]['argv'] ||= []) << e1.text
                   }
                 }
                 # Status Domain
                 hst = dbi[:status] = {}
                 (doc[:domain]['status'] || []).each{|e0|
                   p = (hst[e0.name.to_sym] ||= {})
                   case e0.name
                   when 'alias'
                     e0.attr2item(p)
                   else
                     e0.attr2item(p, 'ref')
                   end
                 }
                 init_watch(doc, dbi)
                 dbi['proj'] = @proj
                 dbi['site_id'] = dbi['ins_id'] = dbi['id']
                 dbi['frm_site'] ||= dbi['id']
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
