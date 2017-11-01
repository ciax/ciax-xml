#!/usr/bin/ruby
require 'libxmlcore'
require 'rexml/document'

module CIAX
  module Xml
    # REXML
    class Elem < Core
      def initialize(f)
        if f.is_a? REXML::Element
          @e = f
        else
          super
        end
      end

      def ns
        @e.namespace
      end

      def text
        return if @e.has_elements?
        t = @e.text.to_s
        t unless t.empty?
      end

      def find(xpath)
        verbose { "FindXpath:#{xpath}" }
        REXML::XPath.each(@e.root, "//ns:#{xpath}", 'ns' => ns) do |e|
          _mkelem(e) { |ne| yield ne }
        end
      end

      private

      def _attr_view_
        super.to_a
      end

      def _get_file_(f)
        REXML::Document.new(open(f)).root
      end
    end
  end
end
