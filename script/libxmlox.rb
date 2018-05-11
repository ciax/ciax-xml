#!/usr/bin/ruby
require 'libenumx'
require 'ox'

module CIAX
  # Xml module
  module Xml
    # Using Ox
    # gem install ox
    class Elem < Hashx
      include Msg
      def initialize(f)
        cfg_err('Parameter shoud be String or Node') unless f.is_a? String
        test('r', f) || cfg_err("Can't read file #{f}")
        @e = Ox.load_file(f).nodes.first
      end

      def text
        t = @e.text.to_s
        t unless t.empty?
      end

      def find(xpath)
        verbose { "FindXpath:#{xpath}" }
        @e.locate(xpath).each do |e|
          yield dup.sete(e)
        end
      end

      def ns
        @e.attributes[:xmlns]
      end

      def sete(e)
        @e = e
        self
      end

      def to_s
        @e.to_s
      end

      def [](key)
        @e.attributes[key.to_s]
      end

      def name
        @e.value
      end

      def map
        ary = []
        each do |e|
          ary << (yield e)
        end
        ary
      end

      def each
        @e.each do |e|
          yield dup.sete(e)
        end
      end

      # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
      def to_h(_key = :val)
        @e.attributes
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

      def ___attr_to_a(id, &at_proc)
        atrb = Hashx.new
        to_h.each do |k, v|
          atrb[k] = at_proc ? yield(v) : v
        end
        key = atrb.delete(id) || give_up("No such key (#{id})")
        [key, atrb]
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libgetopts'
      GetOpts.new('[type] (adb,fdb,idb,ddb,mdb,cdb,sdb,hdb)') do |_o, args|
        file = Msg.xmlfiles(args.shift).first.to_s
        ele = Elem.new(file)
        ele.each { |e| puts e.name }
      end
    end
  end
end
