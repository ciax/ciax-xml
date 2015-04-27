#!/usr/bin/ruby
require "libappdb"

module CIAX
  module Ins
    class Db < Db
      include Wat::Db
      def initialize(proj=PROJ)
        super('idb',proj)
      end

      # overwrite App::Db
      def set(id=nil)
        cpy=super
        cpy.cover(App::Db.new.set(cpy['app_id']))
      end

      private
      def doc_to_db(doc)
        db=Dbi[doc[:attr]]
        hcmd=db[:command]={}
        algrp={'caption' => 'Alias','column' => 2,:members =>{}}
        (doc[:domain]['alias']||[]).each{|e0|
          (hcmd[:alias]||={})[e0['id']]=e0['ref']
          algrp[:members][e0['id']]=e0['label']
        }
        (hcmd[:group]||={})['gal']=algrp
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
        db=Db.new(ARGV.shift).set(ARGV.shift)
      rescue
        Msg.usage("(opt) [id] (key) ..")
        Msg.exit
      end
      puts db.path(ARGV)
    end
  end
end
