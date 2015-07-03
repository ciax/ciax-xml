#!/usr/bin/ruby
require "libappdb"

module CIAX
  module Ins;Color=6
    class Db < Db
      include Wat::Db
      def initialize(proj=PROJ)
        super('idb',proj)
      end

      # overwrite App::Db
      def get(id=nil)
        cpy=super
        cpy.cover(App::Db.new.get(cpy['app_id']))
      end

      private
      def doc_to_db(doc)
        db=Dbi[doc[:attr]]
        # Command Domain
        hcmd=db[:command]={}
        algrp={'caption' => 'Alias','column' => 2,:members =>[]}
        (doc[:domain]['alias']||[]).each{|e0|
          e0.attr2item(hcmd[:alias]||={})
          algrp[:members] << e0['id']
        }
        (hcmd[:group]||={})['gal']=algrp
        # Status Domain
        (doc[:domain]['status']||[]).each{|e0|
          p=(db[:status]||={})
          if e0.name == 'group'
            e0.attr2item(p[:group]||={},'ref')
          else
            e0.attr2db(p,'ref')
          end
        }
        init_watch(doc,db)
        db['site_id']=db['ins_id']=db['id']
        db['frm_site']||=db['id']
        db
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
