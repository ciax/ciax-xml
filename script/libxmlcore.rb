#!/usr/bin/env ruby
require 'libhashx'

module CIAX
  module Xml
    # Shared module for XML LIB
    # Common with LIBXML,REXML
    class Core
      include Msg
      attr_reader :ns
      def initialize(f)
        @e = _get_doc(f)
        @ns = nil
        @attr = {}
      end

      # Getting Element
      def [](key)
        @e.attributes[key.to_s]
      end

      def text
        @e.text
      end

      def name
        @e.name
      end

      # Convert to String
      def to_s
        @e.to_s
      end

      # Enumerble
      def each
        @e.each_element do |e|
          yield self.class.new(e)
        end
      end

      def find(xpath)
        verbose { "FindXpath:#{xpath}" }
      end

      # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
      def to_h
        h = Hashx.new
        h[:val] = text if text
        @attr.each { |k, v| h[k.to_sym] = v.dup }
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
        key, atrb = ___attr_to_a(id, &at_proc)
        if id != :ref && db.key?(key)
          alert('ATTRDB: Duplicated ID [%s]', key)
          db.delete(key)
        end
        db.get(key) { Hashx.new }.update(atrb)
        key
      end

      alias each_value each

      private

      def ___attr_to_a(id, &at_proc)
        atrb = Hashx.new
        to_h.each do |k, v|
          atrb[k] = at_proc ? yield(v) : v
        end
        key = atrb.delete(id) || give_up("No such key (#{id})")
        [key, atrb]
      end

      def _get_doc(f)
        return f if f.is_a?(_element)
        cfg_err('Parameter shoud be String or Node') unless f.is_a? String
        test('r', f) || cfg_err("Can't read file #{f}")
        verbose { "Loading xml file #{f}" }
        _get_file(f)
      end

      # Set Class of XML Element
      def _element; end

      # Set XML file loading
      def _get_file(f); end
    end
  end
end
