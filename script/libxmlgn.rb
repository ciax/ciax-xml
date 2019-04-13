#!/usr/bin/env ruby
require 'libxmlcore'
require 'xml'

module CIAX
  module Xml
    # Gnu XML LIB
    class Elem < Core
      def initialize(f)
        super
        @ns = @e.namespaces.default
        @attr = @e.attributes.to_h
      end

      def text
        @e.each do |n|
          return n.content if n.text? && /[\S]/ =~ n.content
        end
        nil
      end

      # pick same ns nodes even if it is in another tree
      def find(xpath)
        super
        @e.doc.find("//ns:#{xpath}", "ns:#{@ns}").each do |e|
          yield Elem.new(e)
        end
      end

      private

      def _element
        XML::Node
      end

      def _get_file(f)
        XML::Document.file(f).root
      end
    end
  end
end
