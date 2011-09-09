#!/usr/bin/ruby
require "libmsg"
require "libmodxml"
require "xml"
require "libmsg"

class Xml
  include ModXml
  def initialize(f=nil)
    @v=Msg::Ver.new("Xml",4)
    case f
    when String
      test(?r,f) || raise(SelectID)
      @e=XML::Document.file(f).root
      @v.msg{@e.namespaces.default}
    when XML::Node
      @e=f
    when nil
      doc=XML::Document.new
      @e=doc.root=XML::Node.new('blank')
    else
      Msg.err("Parameter shoud be String or Node")
    end
  end

  def ns
    @e.namespaces.default
  end

  def to_h # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
    @e.attributes.to_h
  end

  def text
    @e.each{|n|
      return n.content if n.text?
    }
    nil
  end

  # pick same ns nodes even if it is in another tree
  def find(xpath)
    @v.msg{"FindXpath:#{xpath}"}
    @e.doc.find("//ns:#{xpath}","ns:#{ns}").each{|e|
      @v.msg(1){"<#{e.name} #{e.attributes.to_h}>"}
      yield Xml.new(e)
      @v.msg(-1){"</#{e.name}>"}
    }
  end

  def each
    @e.each_element{|e|
      @v.msg(1){"<#{e.name} #{e.attributes.to_h}>"}
      yield Xml.new(e)
      @v.msg(-1){"</#{e.name}>"}
    }
  end
end
