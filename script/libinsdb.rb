#!/usr/bin/ruby
require "libappdb"

module CIAX
  module Ins
    class Db < Db
      def initialize
        super('idb',ENV['PROJ'])
      end

      def set(id=nil)
        self['id']=id
        super
      end

      # overwrite App::Db
      def cover_app
        cover(App::Db.new.set(self['app_id']))
      end

      private
      def doc_to_db(doc)
        hash=Hash[doc]
        algrp={'caption' => 'Alias','column' => 2,:members =>{}}
        doc.domain('alias').each{|e0|
          (hash[:alias]||={})[e0['id']]=e0['ref']
          algrp[:members][e0['id']]=e0['label']
        }
        (hash[:cmdgrp]||={})['gal']=algrp
        doc.domain('status').each{|e0|
          p=(hash[:status]||={})
          if e0.name == 'group'
            e0.attr2item(hash[:statgrp]||={},'ref')
          else
            e0.attr2db(p,'ref')
          end
        }
        hash
      end
    end
  end

  class App::Db
    def ext_ins(id)
      ins=Ins::Db.new.set(id)
      deep_update(ins)
    end
  end

  if __FILE__ == $0
    begin
      GetOpts.new("",{"f"=>"frm mode"})
      id=ARGV.shift
      db=Ins::Db.new.set(id)
    rescue InvalidID
      $opt.usage("(opt) [id] (key) ..")
      Msg.exit
    end
    db=db.cover_app unless $opt["f"]
    puts db.path(ARGV)
  end
end
