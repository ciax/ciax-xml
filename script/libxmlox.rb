#!/usr/bin/ruby
require 'libenum'
require 'ox'

module CIAX
  module Xml
    # Ox
    # gem install ox
    attr_reader :root
    class Elem < Hashx
      include Msg
      def initialize(f)
        if f.is_a? Elem
          @root = super(f).root
        else
          if f.is_a? String
            test('r', f) || cfg_err("Can't read file #{f}")
            return _get_file(f)
          end
          cfg_err('Parameter shoud be String or Node')
        end
      end

      def ns
        @e.namespace
      end

      def text
        t = @e.text.to_s
        t unless t.empty?
      end

      def find(xpath)
        verbose { "FindXpath:#{xpath}" }
        REXML::XPath.each(@e.root, "//ns:#{xpath}", 'ns' => ns) do |e|
          _mkelem(e) { |ne| yield ne }
        end
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
        _attr_elem.each { |k, v| h[k.to_sym] = v.dup }
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
        key, atrb = ___attr_to_a(id, &at_proc)
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

      def ___attr_to_a(id, &at_proc)
        atrb = Hashx.new
        to_h.each do |k, v|
          atrb[k] = at_proc ? yield(v) : v
        end
        key = atrb.delete(id) || give_up("No such key (#{id})")
        [key, atrb]
      end

      def ___get_doc(f)
        if f.is_a? String
          test('r', f) || cfg_err("Can't read file #{f}")
          return _get_file(f)
        end
        cfg_err('Parameter shoud be String or Node')
      end

      def _get_file(f)
        @root = Ox.load(open(f), mode: :hash)
      end
    end
  end
end
