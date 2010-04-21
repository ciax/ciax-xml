#!/usr/bin/ruby
require "libverbose"
class XmlDb
  protected
  attr_accessor :doc

  def initialize(doc,xpath)
    @property=doc.root.elements.first.attributes
    @v=Verbose.new("#{doc.root.name}/#{@property['id']}".upcase)
    @var=Hash.new
    begin
      @doc=doc.elements[xpath]
    rescue
      p $!
      raise("No such Xpath")
    end
  end

  # Public Method
  public
  attr_reader :property
  def node_with_id(id)
    begin
      e=@doc.elements[".//[@id='#{id}']"] || raise
    rescue
      list_id('./')
      raise("No such a command")
    end
    copy_self(e)
  end

  def set_var!(hash)
    @var.update(hash)
  end

  # Access Attributes
  def [](key)
    a=@doc.attributes[key] || return
    a.to_s
  end

  def attr_with_key(key)
    val=@doc.attributes[key]
    yield val if val
  end

  def each_attr
    @doc.attributes.each do |key,val|
      yield key,val
    end
  end

  def add_attr(hash=nil)
    h=hash || Hash.new
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
    attr_with_key('format') do |fmt|
      str=fmt % code
      @v.msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]",1)
      code=str
    end
    code.to_s
  end

  def text
    @v.msg("Getting text[#{@doc.text}]",1)
    return @doc.text unless r=@doc.attributes['ref']
    @v.msg("Getting text from ref [#{r}]",1)
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
