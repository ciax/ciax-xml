#!/usr/bin/ruby
require "rexml/document"
include REXML

class SelectID < RuntimeError ; end

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
    doc.each_element {|e| self[e.name]=e }
    doc.attributes.each{|k,v| self[k]=v }
  end

  def select_id(xpath,id)
    if id && id != ''
      self[xpath].each_element_with_attribute('id',id){|e| return e }
    end
    $errmsg << "== Command List ==\n"
    self[xpath].each_element { |e| addlist(e) }
    raise(SelectID,$errmsg) unless $errmsg.empty?
  end

  private
  def getdoc(f)
    Document.new(f).root.elements.first
  end

  def addlist(e)
    a=e.attributes
    $errmsg << " %-10s: %s\n" % [a['id'],a['label']] if a['label']
  end

end
