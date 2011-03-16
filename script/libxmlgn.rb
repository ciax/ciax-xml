#!/usr/bin/ruby
require "xml"

class SelectID < RuntimeError ; end

class XmlGn
  include Enumerable

  def initialize(f)
    case f
    when String
      test(?r,f) || raise(SelectID)
      @e=XML::Document.file(f).root
    when XML::Node
      @e=f
    else
      raise "Parameter shoud be String or Node"
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

  def name
    @e.name
  end

  def text
    txt=@e.content
    (txt == '') ? nil : txt
  end

  # select element with key=val, or display list
  def select(key,val)
    @e.each_element{|e|
      return XmlGn.new(e) if e.attributes[key] == val
    } if val
    raise SelectID,list(key)
  end

  def list(key)
    inject(''){|msg,e|
      msg << " %-10s: %s\n" % [e[key],e['label']] if e[key] && e['label']
      msg
    }
  end

  def find_each(xpath)
    ns=@e.namespaces.namespace.to_s
    @e.doc.find("//ns:#{xpath}","ns:#{ns}").each{|e|
      yield XmlGn.new(e)
    }
  end
end
