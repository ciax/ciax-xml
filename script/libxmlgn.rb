#!/usr/bin/ruby
require 'libxmlshare'
require 'xml'

module CIAX
  module Xml
    # Gnu XML LIB
    class Gnu
      include Share
      def initialize(f = nil)
        @e = _get_doc(f)
      end

      def ns
        @e.namespaces.default
      end

      # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
      def to_h(key = :val)
        h = Hashx.new
        @e.attributes.to_h.each do |k, v|
          h[k.to_sym] = v
        end
        t = text
        h[key] = t if t
        h
      end

      def text
        @e.each do|n|
          return n.content if n.text? && /[\S]/ =~ n.content
        end
        nil
      end

      # pick same ns nodes even if it is in another tree
      def find(xpath)
        verbose { "FindXpath:#{xpath}" }
        @e.doc.find("//ns:#{xpath}", "ns:#{ns}").each do|e|
          enclose("<#{e.name} #{e.attributes.to_h}>", "</#{e.name}>") do
            yield Gnu.new(e)
          end
        end
      end

      def each
        @e.each_element do|e|
          enclose("<#{e.name} #{e.attributes.to_h}>", "</#{e.name}>") do
            yield Gnu.new(e)
          end
        end
      end

      # Adapt to both Gnu, Hash
      alias_method :each_value, :each

      private

      def _get_doc(f)
        return _get_new unless f
        return f if f.is_a? XML::Node
        return _get_file(f) if f.is_a? String
        Msg.cfg_err('Parameter shoud be String or Node')
      end

      def _get_file(f)
        test('r', f) || fail(InvalidID)
        e = XML::Document.file(f).root
        verbose { e.namespaces.default.to_s }
        e
      end

      def _get_new
        e = XML::Node.new('blank')
        XML::Document.new.root = e
        e
      end
    end
  end
end
