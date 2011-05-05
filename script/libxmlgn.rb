#!/usr/bin/ruby
require "xml"
require "libverbose"

class XmlGn
  def initialize(f)
    @v=Verbose.new("Xml",2)
    case f
    when String
      test(?r,f) || raise(SelectID)
      @e=XML::Document.file(f).root
    when XML::Node
      @e=f
    else
      @v.err("Parameter shoud be String or Node")
    end
  end

  def each
    @e.each_element{|e|
      yield XmlGn.new(e)
    }
  end

  def [](key)
    @e.attributes[key]
  end

  def to_h # Don't use Hash[@e.attributes] (=> {"id"=>"id='id'"})
    @e.attributes.to_h
  end

  def to_s
    @e.to_s
  end

  def name
    @e.name
  end

  def text
    @e.each{|n|
      return n.content if n.text?
    }
    nil
  end

  def find_each(xpath)
    ns=@e.namespaces.namespace.to_s
    @e.doc.find("//ns:#{xpath}","ns:#{ns}").each{|e|
      yield XmlGn.new(e)
    }
  end
end
