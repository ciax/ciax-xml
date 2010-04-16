#!/usr/bin/ruby
require "rexml/document"
include REXML
require "libverbose"
#TopNode required
class XmlDb
  protected
  attr_writer :doc

  def initialize(db = nil ,type = nil)
    pre="#{ENV['XMLPATH']}/#{db}"
    path="#{pre}-#{type}.xml"
    begin
      @doc=Document.new(open(path)).elements[TopNode]
    rescue
      Dir.glob("#{pre}-*.xml").each do |p|
        @doc=Document.new(open(p)).root
        list_id('/*')
      end
      raise("No such a db")
    end
    @type=type
    @v=Verbose.new("#{db}/#{type}".upcase)
    @var=Hash.new
  end

  # Public Method
  public

  def set_var(hash)
    @var.update(hash)
  end

  # Access Attributes
  def [](key)
    a=@doc.attributes[key] || return
    a.to_s
  end

  def attr?(key)
    val=@doc.attributes[key]
    yield val if val
  end

  def each_attr
    @doc.attributes.each do |key,val|
      yield key,val
    end
  end

  def attr_to_hash
    h=Hash.new
    @doc.attributes.each do |key,val|
      h[key]=val
    end
    h
  end

  #Access Node
  def each_node
    @doc.elements.each do |e|
      yield copy_self(e)
    end
    self
  end

  def node_with_text(text)
    @doc.elements.each do |e|
      d=copy_self(e)
      yield d if d.text == text
    end
  end

  def node_with_name(name)
    @doc.elements.each("./#{name}") do |e|
      yield copy_self(e)
    end
  end

  def node_with_attr(key,val)
    @doc.each_element_with_attribute(key,val) do |e|
      return copy_self(e)
    end
  end

  # Text Convert
  def format(code)
    attr?('format') do |fmt|
      code=fmt % code
    end
    code.to_s
  end

  def text
    return @doc.text unless r=@doc.attributes['ref']
    @var[r] || raise(IndexError,"No reference for [#{r}]")
  end

  def name
    @doc.name
  end

  # Private Method
  private
  def copy_self(e)
    d=clone
    d.doc=e
    d
  end

  # Error Handling
  def list_id(xpath)
    @doc.elements.each(xpath+'/[@id]') do |d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    end
  end

end
