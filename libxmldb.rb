#!/usr/bin/ruby
require "rexml/document"
include REXML
#TopNode required
class XmlDb
  attr_writer :doc
  def initialize(db = nil ,type = nil)
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    begin
      @doc=Document.new(open(path)).elements[TopNode]
    rescue
      Dir.glob("#{pre}-*.xml").each do |p|
        @doc=Document.new(open(p)).root
        listId('/*')
      end
      raise("No such a file")
    end
  end
  def selfcp(e)
    d=clone
    d.doc=e
    d
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
    return unless e
    yield selfcp(e)
    self
  end

  def [](key)
    a=@doc.attributes[key] || return
    a.to_s
  end

  def each
    @doc.elements.each do |e|
      if e.name == 'select' and @sel
        @sel.elements.each do |s|
          yield selfcp(s)
        end
      else
        yield selfcp(e)
      end
    end
    self
  end

  def name
    @doc.name
  end

  def trText(code)
    @doc.attributes.each_attribute do |a|
      case a.expanded_name
      when 'mask'
        code=eval "#{code}#{a.value}"
      when 'pack'
        code=[code].pack(a.value)
      when 'unpack'
        code=code.unpack(a.value).first
      when 'format'
        code=a.value % code
      end
    end
    code.to_s
  end

  def getText(var)
    return @doc.text unless r=@doc.attributes['ref']
    if var[r]
      return var[r]
    else
      raise "No reference for [#{r}]"
    end
  end

  # Error Handling
  def listId(xpath)
    @doc.elements.each(xpath+'/[@id]') do |d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    end
  end
end
