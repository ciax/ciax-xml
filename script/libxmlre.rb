#!/usr/bin/ruby
require 'libxmlshare'
require 'rexml/document'

module CIAX
  module Xml
    # REXML
    class Elem
      include Share
      def initialize(f = nil)
        @e = _get_doc(f)
      end

      def ns
        @e.namespace
      end

      def text
        t = @e.text.to_s.strip
        t unless t.empty?
      end

      def find(xpath)
        verbose { "FindXpath:#{xpath}" }
        REXML::XPath.each(@e.root, "//ns:#{xpath}", 'ns' => ns) do |e|
          yield Elem.new(e)
        end
      end

      def each
        @e.each_element do |e|
          enclose("<#{e.name} #{e.attributes.to_a}>", "</#{e.name}>") do
            yield Elem.new(e)
          end
        end
      end

      alias each_value each

      private

      def _get_doc(f)
        return REXML::Element.new unless f
        return f if f.is_a? REXML::Element
        return _get_file(f) if f.is_a? String
        Msg.cfg_err('Parameter shoud be String or Element')
      end

      def _get_file(f)
        test('r', f) || raise(InvalidID)
        e = REXML::Document.new(open(f)).root
        verbose { e.namespaces.default.to_s }
        e
      end
    end
  end
end
