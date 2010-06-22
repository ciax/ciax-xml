#!/usr/bin/ruby
require "rexml/document"
include REXML
class XmlDoc < Hash

  def initialize(db = nil ,type = nil)
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    begin
      doc=Document.new(open(path)).root.elements.first
    rescue
      list=Array.new
      Dir.glob("#{pre}-*.xml").each {|p|
        list << Document.new(open(p)).root.elements.first
      }
      mklist(list)
    end
    doc.each_element {|e| self[e.name]=e }
    doc.attributes.each{|k,v| self[k]=v }
  end

  def select_id(id)
    self[:cid]=id
    self['selection'].each_element_with_attribute('id',id){|e| return e }
    list_id('selection')
  end

  # Error Handling
  def list_id(name)
    list=Array.new
    self[name].each_element { |e| list << e }
    mklist(list)
  end

  private
  def mklist(ary)
    list=Array.new
    ary.each { |e|
      a=e.attributes
      list << "#{a['id']}\t:#{a['label']}" if a['label']
    }
    raise(list.join("\n")) if list.size > 0
  end

end
