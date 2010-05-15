#!/usr/bin/ruby
require "rexml/document"
include REXML
class XmlDoc < Document
  attr_accessor :property
  def initialize(db = nil ,type = nil)
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    begin
      super(open(path))
    rescue
      Dir.glob("#{pre}-*.xml").each do |p|
        super(open(p))
        list_id('/*')
      end
      raise ("No such a db")
    end
    @property=root.elements.first.attributes
  end

  # Error Handling
  def list_id(xpath)
    elements.each(xpath+'/[@id]') do |d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    end
  end

end
