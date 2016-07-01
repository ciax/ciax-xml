#!/usr/bin/ruby
require 'libenumx'

module CIAX
  module Xml
    # Shared module for XML LIB
    # Common with LIBXML,REXML
    class Core
      include Msg
      def initialize(f)
        @e = _get_doc(f)
      end

      def to_s
        @e.to_s
      end

      def [](key)
        @e.attributes[key.to_s]
      end

      def name
        @e.name
      end

      def map
        ary = []
        each do |e|
          ary << (yield e)
        end
        ary
      end

      def each
        @e.each_element do |e|
          _mkelem(e) { |ne| yield ne }
        end
      end

      # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
      def to_h(key = :val)
        h = Hashx.new
        _attr_elem.each { |k, v| h[k.to_sym] = v }
        t = text
        h[key] = t if t
        h
      end

      def attr2db(db, id = 'id', &at_proc) # deprecated
        # <xml id='id' a='1' b='2'> => db[:a][id]='1', db[:b][id]='2'
        type?(db, Hash)
        key, atrb = _get_attr_(id, &at_proc)
        atrb.each do |str, v|
          sym = str.to_sym
          db[sym] = Hashx.new unless db.key?(sym)
          db[sym][key] = v
          verbose { 'ATTRDB:' + str.upcase + ":[#{key}] : #{v}" }
        end
        key
      end

      def attr2item(db, id = :id, &at_proc) # deprecated
        # <xml id='id' a='1' b='2'> => db[id][a]='1', db[id][b]='2'
        type?(db, Hashx)
        key, atrb = _attr_to_a(id, &at_proc)
        if id != :ref && db.key?(key)
          alert("ATTRDB: Duplicated ID [#{key}]")
          db.delete(key)
        end
        db.get(key) { Hashx.new }.update(atrb)
        key
      end

      # Adapt to both Gnu, Hash
      alias each_value each

      private

      def _mkelem(e)
        enclose("<#{e.name} #{_attr_view}>", "</#{e.name}>") do
          yield Elem.new(e)
        end
      end

      def _attr_elem
        @e.attributes
      end

      def _attr_view
        @e.attributes
      end

      def _attr_to_a(id, &at_proc)
        atrb = Hashx.new
        to_h.each do |k, v|
          atrb[k] = at_proc ? yield(v) : v
        end
        key = atrb.delete(id) || Msg.give_up("No such key (#{id})")
        [key, atrb]
      end

      def _get_doc(f)
        if f.is_a? String
          test('r', f) || raise(InvalidID)
          return _get_file(f)
        end
        Msg.cfg_err('Parameter shoud be String or Node')
      end

      def _get_file(f); end
    end
  end
end
