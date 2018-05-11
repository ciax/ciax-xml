#!/usr/bin/ruby
require 'libenumx'
require 'ox'

module CIAX
  # Xml module
  module Xml
    # Using Ox
    # gem install ox
    class Elem
      include Msg
      attr_reader :ns
      def initialize(f)
        cfg_err('Parameter shoud be String or Node') unless f.is_a? String
        test('r', f) || cfg_err("Can't read file #{f}")
        doc = Ox.load_file(f)
        @ns = doc.attributes[:xmlns]
        @e = doc.nodes.first
      end

      def text
        @e.text
      end

      def find(xpath)
        verbose { "FindXpath:#{xpath}" }
        @e.locate(xpath).each do |e|
          yield dup.sete(e)
        end
      end

      def sete(e)
        @e = e
        @ns = e[:xmlns] || @ns
        self
      end

      def to_s
        @e.to_s
      end

      def [](key)
        @e.attributes[key.to_sym]
      end

      def name
        @e.value
      end

      def each
        @e.each do |e|
          yield dup.sete(e) if e.is_a? Ox::Element
        end
      end

      # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
      def to_h
        h = Hashx.new
        h[:val] = text if text
        h.update(@e.attributes)
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
      GetOpts.new('[type]') do |_o, args|
        file = Msg.xmlfiles(args.shift).first.to_s
        Msg.args_err(%w(adb fdb idb ddb mdb cdb sdb hdb)) if file.empty?
        ele = Elem.new(file)
        ele.each { |e| puts e.name }
      end
    end
  end
end
