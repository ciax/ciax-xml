#!/usr/bin/ruby
require "libmsg"
require "libmodxml"
require "rexml/document"
include REXML

class Xml
  extend Msg::Ver
  include ModXml
  def initialize(f=nil)
    Xml.init_ver(self,4)
    case f
    when String
      test(?r,f) || raise(SelectID)
      @e=Document.new(open(f)).root
      Xml.msg{ns}
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
      Xml.msg(1){"<#{e.name} #{e.attributes}>"}
      yield Xml.new(e)
      Xml.msg(-1){"</#{e.name}>"}
    }
  end

  def each
    @e.each_element{|e|
      Xml.msg(1){"<#{e.name} #{e.attributes}>"}
      yield Xml.new(e)
      Xml.msg(-1){"</#{e.name}>"}
    }
  end
end
