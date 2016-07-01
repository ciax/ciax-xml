#!/usr/bin/ruby
require "libxmlshare"
require "rexml/document"

module CIAX
  module Xml
    class Elem
      include REXML
      include Share
      def initialize(f=nil)
        case f
        when String
          test(?r,f) || raise(InvalidID)
          @e=Document.new(open(f)).root
        when Element
          @e=f
        when nil
          @e=Element.new
        else
          raise "Parameter shoud be String or Element"
        end
      end

      def ns
        @e.namespace
      end

      def text
        t = @e.text.to_s.strip
        t unless t.empty?
      end

      def each(xpath=nil)
        @e.each_element{|e|
          yield Elem.new(e)
        }
      end

      alias find each
    end
  end
end
