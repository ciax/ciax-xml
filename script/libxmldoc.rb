#!/usr/bin/ruby
require "rexml/document"
include REXML
class XmlDoc < Hash

  def initialize(db = nil ,type = nil)
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    f=open(path)
  rescue
    list=Array.new
    Dir.glob("#{pre}-*.xml").each {|p|
      list << getdoc(open(p))
    }
    mklist(list)
  else
    doc=getdoc(f)
    doc.each_element {|e| self[e.name]=e }
    doc.attributes.each{|k,v| self[k]=v }
  end

  def select_id(xpath,id)
    if id && id != ''
      self[:cid]=id
      self[xpath].each_element_with_attribute('id',id){|e| return e }
    end
    list_id(xpath)
  end

  # Error Handling
  def list_id(name)
    list=Array.new
    self[name].each_element { |e| list << e }
    mklist(list)
  end

  private
  def getdoc(f)
    Document.new(f).root.elements.first
  end

  def mklist(ary)
    list=Array.new
    ary.each { |e|
      a=e.attributes
      list << " %-10s: %s" % [a['id'],a['label']]if a['label']
    }
    raise(list.join("\n")) if list.size > 0
  end

end
