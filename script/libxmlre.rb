#!/usr/bin/ruby
require "libmsg"
require "libxmlshare"
require "rexml/document"
include REXML

module Xml
  class Re
    extend Msg::Ver
    include Share
    def initialize(f=nil)
      Re.init_ver(self,4)
      case f
      when String
        test(?r,f) || raise(InvalidDEV)
        @e=Document.new(open(f)).root
        Re.msg{ns}
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

    def to_h # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
      h={}
      @e.attributes.each{|k,v| h[k]=v }
      h
    end

    def text
      @e.text
    end

    def find(xpath)
      xpath=".//"+xpath if xpath
      @e.each_element(xpath){|e|
        Re.msg(1){"<#{e.name} #{e.attributes}>"}
        yield Re.new(e)
        Re.msg(-1){"</#{e.name}>"}
      }
    end

    def each
      @e.each_element{|e|
        Re.msg(1){"<#{e.name} #{e.attributes}>"}
        yield Re.new(e)
        Re.msg(-1){"</#{e.name}>"}
      }
    end
  end
end
