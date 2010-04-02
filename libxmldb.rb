#!/usr/bin/ruby
require "rexml/document"
include REXML
class XmlDb
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
    @tn="/"
    @type=type
  end
  def substitute(node,xpath)
    xpath=@tn+xpath
    node.elements.each do |e|
      @doc.insert_before(xpath,e)
    end
    @doc.delete_element(xpath)
    self
  end
  def top_node_xpath(xpath)
    @tn=xpath
    self
  end
  def top_node
    @doc.elements[@tn]
  end
  def select_id(id)
    xpath='//select'
    begin
      sel=@doc.elements[@tn+"//[@id='#{id}']"] || raise
    rescue
      listId(@tn+xpath)
      raise("No such a command")
    end
    substitute(sel,xpath)
    self
  end
  def node?(xpath)
    e=@doc.elements[@tn+xpath]
    yield e if e 
  end
  def show
    puts @doc.elements[@tn]
  end
  # Error Handling
  def listId(xpath)
    @doc.elements.each(xpath+'/[@id]') do |d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    end
  end
end
