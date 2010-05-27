#!/usr/bin/ruby
require "rexml/document"
include REXML
class XmlDoc < Document
  attr_reader :property

  def initialize(db = nil ,type = nil)
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    begin
      super(open(path))
    rescue
      Dir.glob("#{pre}-*.xml").each {|p|
        super(open(p))
        list_id('/*')
      }
      raise ("No such a db")
    end
    @property=root.elements.first.attributes
  end

  def select_id(xpath,id)
    if e=elements[xpath+"/[@id='#{id}']"]
      return e
    else
      list_id(xpath)
    end
    raise "No such ID"
  end

  # Error Handling
  def list_id(xpath)
    elements.each(xpath+'/[@id]') {|d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    }
  end

end
