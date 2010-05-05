#!/usr/bin/ruby
require "libmodver"
class XmlDb
  include ModVer
  protected
  attr_accessor :doc

  def initialize(doc,xpath)
    @property=doc.root.elements.first.attributes
    @title="#{doc.root.name}/#{@property['id']}".upcase
    @var=Hash.new # Use for par,cc
    begin
      @doc=doc.elements[xpath]
    rescue
      p $!
      err("No such Xpath")
    end
  end

  # Public Method
  public
  attr_reader :property

  def set_var!(hash,namespace=nil)
    if namespace
      hash.each do |key,val|
        @var["#{namespace}:#{key}"]=val
      end
    else
      @var.update(hash)
    end
    self
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

  def child_node # Node pick up for macro
    copy_self(@doc.elements[1])
  end

  def next_node! # Node pick up for macro
    @doc=@doc.next_element
    self
  end

  def elem_with_id(id) # Interface
    @var.clear
    @doc.elements[".//[@id='#{id}']"]
  end


  # Text Convert
  def format(code)
    attr_with_key('format') do |fmt|
      str=fmt % code
      msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]",1)
      code=str
    end
    code.to_s
  end

  def text
    attr_with_key('ref') do |r|
      msg("Getting text from ref [#{r}]",1)
      return @var[r] || raise(IndexError,"No reference for [#{r}]")
    end
    msg("Getting text[#{@doc.text}]",1)
    return @doc.text
  end

  def text_convert
    attr_with_key('ref') do |r|
      msg("Getting ref[#{@var[r]}] and text[#{@doc.text}]",1)
      yield @var[r],@doc.text
    end
    msg("Getting text[#{@doc.text}]",1)
    return @doc.text
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

