#!/usr/bin/ruby
require 'libmsg'

module CIAX
  module Xml
    module Share
      include Msg
      # Common with LIBXML,REXML
      def to_s
        @e.to_s
      end

      def [](key)
        @e.attributes[key]
      end

      def name
        @e.name
      end

      def map
        ary=[]
        each{|e|
          ary << (yield e)
        }
        ary
      end

      def attr2db(db,id='id')
        # <xml id='id' a='1' b='2'> => db[:a][id]='1', db[:b][id]='2'
        type?(db,Hash)
        attr={}
        to_h.each{|k,v|
          if defined?(yield)
            attr[k] = yield k,v
          else
            attr[k] = v
          end
        }
        key=attr.delete(id) || Msg.abort("No such key (#{id})")
        attr.each{|str,v|
          sym=str.to_sym
          db[sym]={} unless db.key?(sym)
          db[sym][key]=v
          verbose("XmlShare","ATTRDB:"+str.upcase+":[#{key}] : #{v}")
        }
        key
      end

      def add_item(db,id='id')
        # <xml id='id' a='1' b='2'> => db[id][a]='1', db[id][b]='2'
        type?(db,Hash)
        attr={}
        to_h.each{|k,v|
          if defined?(yield)
            attr[k] = yield k,v
          else
            attr[k] = v
          end
        }
        key=attr.delete(id) || Msg.abort("No such key (#{id})")
        db[key]=attr
        key
      end

      def add_attr(db,id='id')
        # <xml id='id' a='1' b='2'> => db[id][a]='1', db[id][b]='2'
        type?(db,Hash)
        attr={}
        to_h.each{|k,v|
          if defined?(yield)
            attr[k] = yield k,v
          else
            attr[k] = v
          end
        }
        key=attr.delete(id) || Msg.abort("No such key (#{id})")
        db[key]=attr
      end
    end
  end
end
