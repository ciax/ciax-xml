#!/usr/bin/ruby
require "rexml/document"
include REXML

class SelectID < RuntimeError ; end

class XmlElem

  def initialize(f)
    @e=Document.new(f).root.elements.first
  end

  def each
    @e.each_element{|e|
      yield dup.set(e)
    }
  end

  def [](key)
    @e.attributes[key]
  end

  def to_h
    h={}
    @e.attributes.each{|k,v| h[k]=v}
    h
  end

  def name
    @e.name
  end

  def text
    @e.text
  end

  def selid(id)
    @e.each_element_with_attribute('id',id){|e|
        return dup.set(e)
    } if id
    raise SelectID
  end

  def set(e)
    @e=e
    self
  end
end
