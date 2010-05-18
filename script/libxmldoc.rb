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

  def control_id(id)
    if e=elements["//controls//[@id='#{id}']"]
      if ref=e.attributes['ref']
        return control_id(ref)
      end
      return e
    else
      list_id("//controls/")
      raise "No such ID"
    end
  end

  def status_id(id)
    elements["//status//[@id='#{id}']"] ||
      status_id('default') || raise("Send Only")
  end

  # Error Handling
  def list_id(xpath)
    elements.each(xpath+'/[@id]') {|d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    }
  end

end
