#!/usr/bin/ruby
require "rexml/document"
include REXML
#TopNode required
class XmlDb
  attr_reader :type,:sel
  def initialize(db = nil ,type = nil)
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    begin
      @doc=Document.new(open(path)).root
    rescue
      Dir.glob("#{pre}-*.xml").each do |p|
        @doc=Document.new(open(p)).root
        listId('/*')
      end
      raise("No such a file")
    end
    @type=type
  end
  def top_node
    @doc.elements[TopNode]
  end
  def select_id(id)
    begin
      @sel=@doc.elements[TopNode+"//[@id='#{id}']"] || raise
    rescue
      listId(TopNode+'//select')
      raise("No such a command")
    end
    self
  end
  def node?(xpath)
    e=@doc.elements[TopNode+xpath]
    yield e if e 
  end
  def show
    puts @doc.elements[TopNode]
  end
  # Error Handling
  def listId(xpath)
    @doc.elements.each(xpath+'/[@id]') do |d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    end
  end
end
