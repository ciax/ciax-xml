#!/usr/bin/ruby
require "libxmlshare"
require "xml"

module CIAX
  module Xml
    class Gnu
      include Share
      def initialize(f=nil)
        @ver_color=4
        case f
        when String
          test(?r,f) || raise(InvalidID)
          @e=XML::Document.file(f).root
          verbose("XmlGnu",@e.namespaces.default)
        when XML::Node
          @e=f
        when nil
          doc=XML::Document.new
          @e=doc.root=XML::Node.new('blank')
        else
          Msg.cfg_err("Parameter shoud be String or Node")
        end
      end

      def ns
        @e.namespaces.default
      end

      def to_h # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"}) 
        h=@e.attributes.to_h
        if t=text
          h['val']=t
        end
        h
      end

      def text
        @e.each{|n|
          return n.content if n.text? && /[\S]/ === n.content
        }
        nil
      end

      # pick same ns nodes even if it is in another tree
      def find(xpath)
        verbose("XmlGnu","FindXpath:#{xpath}")
        @e.doc.find("//ns:#{xpath}","ns:#{ns}").each{|e|
          verbose("XmlGnu","<#{e.name} #{e.attributes.to_h}>")
          enclose{
            yield Gnu.new(e)
          }
          verbose("XmlGnu","</#{e.name}>")
        }
      end

      def each
        @e.each_element{|e|
          verbose("XmlGnu","<#{e.name} #{e.attributes.to_h}>")
          enclose{
            yield Gnu.new(e)
          }
          verbose("XmlGnu","</#{e.name}>")
        }
      end
    end
  end
end
