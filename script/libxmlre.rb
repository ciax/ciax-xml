#!/usr/bin/env ruby
require 'libxmlcore'
require 'rexml/document'

module CIAX
  module Xml
    # REXML
    class Elem < Core
      def initialize(f)
        super
        @ns = @e.namespace
        @attr = @e.attributes
      end

      def text
        return if @e.has_elements?
        t = @e.text.to_s
        t unless t.empty?
      end

      def find(xpath)
        super
        REXML::XPath.each(@e.root, "//ns:#{xpath}", 'ns' => @ns) do |e|
          yield Elem.new(e)
        end
      end

      private

      def _element
        REXML::Element
      end

      def _get_file(f)
        REXML::Document.new(open(f)).root
      end
    end
  end
end
