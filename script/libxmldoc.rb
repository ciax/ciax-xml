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
      @xpath='/*'
      Dir.glob("#{pre}-*.xml").each {|p|
        super(open(p))
        list_id rescue true
      }
      raise ("No such a db")
    end
    @property=root.elements.first.attributes
  end

  def select_id(xpath,id)
    @xpath=xpath
    elements[@xpath+"/[@id='#{id}']"]
  end

  # Error Handling
  def list_id
    elements.each(@xpath+'/[@id]') {|d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}" if a['label']
      true
    } && raise("No such ID")
  end

end
