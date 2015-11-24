#!/usr/bin/ruby
require 'libxmlshare'
require 'xml'

module CIAX
  module Xml
    # Gnu XML LIB
    class Gnu
      include Share
      def initialize(f = nil)
        @cls_color = 3
        case f
        when String
          test('r', f) || fail(InvalidID)
          @e = XML::Document.file(f).root
          verbose { @e.namespaces.default }
        when XML::Node
          @e = f
        when nil
          doc = XML::Document.new
          @e = doc.root = XML::Node.new('blank')
        else
          Msg.cfg_err('Parameter shoud be String or Node')
        end
      end

      def ns
        @e.namespaces.default
      end

      # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
      def to_h(key = 'val')
        h = @e.attributes.to_h
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
    end
  end
end
