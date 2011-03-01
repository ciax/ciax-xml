#!/usr/bin/ruby
require "xml"
include XML

class SelectID < RuntimeError ; end

class XmlGn
  include Enumerable

  def initialize(f)
    case f
    when String
      test(?r,f) || raise(SelectID)
      @e=Document.file(f).root
    when Node
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

  def doc
    @e.doc
  end

  def ns
    @e.namespaces.namespace.to_s
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
end
