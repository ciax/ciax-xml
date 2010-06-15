#!/usr/bin/ruby
require "rexml/document"
include REXML
class XmlDoc < Hash

  def initialize(db = nil ,type = nil)
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    begin
      doc=Document.new(open(path))
    rescue
      Dir.glob("#{pre}-*.xml").each {|p|
        doc=Document.new(open(p))
        list_id(doc.root) rescue true
      }
      raise ("No such a db")
    end
    doc.root.elements.first.each_element {|e| self[e.name]=e }
    self['property']=doc.root.elements.first.attributes
  end

  # Error Handling
  def list_id(top)
    top.each_element {|e|
      a=e.attributes
      warn "#{a['id']}\t:#{a['label']}" if a['label']
      true
    } && raise("No such ID")
  end

end
