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

      def [](key)
        @e.attribute(key).to_s
      end

      def ns
        @e.namespace
      end

      def text
        t = @e.text.to_s.strip
        t unless t.empty?
      end

      def find(xpath)
        REXML::XPath.each(@e.root, xpath, ns) do |e|
          yield Elem.new(e)
        end
      end

      def each
        @e.each_element do |e|
          yield Elem.new(e)
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
        REXML::Document.new(open(f)).root
      end
    end
  end
end
