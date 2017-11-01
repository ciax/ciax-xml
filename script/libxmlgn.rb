#!/usr/bin/ruby
require 'libxmlcore'
require 'xml'

module CIAX
  module Xml
    # Gnu XML LIB
    class Elem < Core
      def initialize(f)
        if f.is_a? XML::Node
          @e = f
        else
          super
        end
      end

      def ns
        @e.namespaces.default
      end

      def text
        @e.each do |n|
          return n.content if n.text? && /[\S]/ =~ n.content
        end
        nil
      end

      # pick same ns nodes even if it is in another tree
      def find(xpath)
        verbose { "FindXpath:#{xpath}" }
        @e.doc.find("//ns:#{xpath}", "ns:#{ns}").each do |e|
          _mkelem(e) { |ne| yield ne }
        end
      end

      private

      def _attr_elem_
        super.to_h
      end

      def _attr_view_
        super.to_h
      end

      def _get_file_(f)
        XML::Document.file(f).root
      end
    end
  end
end
