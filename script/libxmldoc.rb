#!/usr/bin/ruby
require "rexml/document"
include REXML

class SelectID < RuntimeError ; end

class Elem
  attr_reader :e

  def initialize(e)
    @e=e
  end

  def each
    @e.each_element{|e|
      yield Elem.new(e)
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
        return Elem.new(e)
    } if id
    raise SelectID
  end
end

class XmlDoc < Hash
  def initialize(db = nil ,type = nil)
    $errmsg=''
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    f=open(path)
  rescue Errno::ENOENT
    list=Array.new
    Dir.glob("#{pre}-*.xml").each {|p|
      addlist(getdoc(open(p)))
    }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  else
    doc=getdoc(f)
    doc.each_element {|e| self[e.name]=Elem.new(e) }
    doc.attributes.each{|k,v| self[k]=v }
  end

  def select_id(xpath,id)
    return self[xpath].selid(id)
  rescue SelectID
    $errmsg << "No such command [#{id}]\n" if id
    $errmsg << "== Command List ==\n"
    self[xpath].each { |e| addlist(e) }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  private
  def getdoc(f)
    Document.new(f).root.elements.first
  end

  def addlist(e)
    $errmsg << " %-10s: %s\n" % [e['id'],e['label']] if e['label']
  end

end
