#!/usr/bin/ruby
require "libverbose"
class XmlDb
  protected
  attr_accessor :cn # Context Node

  def initialize(doc,xpath)
    title="#{doc.root.name}/#{doc.property['id']}".upcase
    @v=Verbose.new(title)
    @var=Hash.new # Use for par,cc
    begin
      @cn=doc.elements[xpath]
    rescue
      p $!
      @v.err("No such Xpath")
    end
  end

  # Public Method
  public
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
    a=@cn.attributes[key] || return
    a.to_s
  end

  def attr_with_key(key)
    val=@cn.attributes[key]
    yield val if val
  end

  def each_attr
    @cn.attributes.each do |key,val|
      yield key,val
    end
  end

  def add_attr(hash=nil)
    h=hash || Hash.new
    @cn.attributes.each do |key,val|
      h[key]=val
    end
    h
  end

  #Access Node
  def each_node
    @cn.elements.each do |e|
      yield copy_self(e)
    end
    self
  end

  def node_with_text(text)
    @cn.elements.each do |e|
      d=copy_self(e)
      yield d if d.text == text
    end
  end

  def node_with_name(name)
    @cn.elements.each("./#{name}") do |e|
      yield copy_self(e)
    end
  end

  def node_with_attr(key,val)
    @cn.each_element_with_attribute(key,val) do |e|
      return copy_self(e)
    end
  end

  def child_node # Node pick up for macro
    copy_self(@cn.elements[1])
  end

  def next_node! # Node pick up for macro
    @cn=@cn.next_element
    self
  end

  def elem_with_id(id) # Interface
    @cn.elements[".//[@id='#{id}']"] || raise("No such an id")
  end

  def node_with_id(id)
    @v.msg("Select [#{id}]",2)
    begin
      e=elem_with_id(id)
    rescue
      list_id('./')
      raise ("No such a command")
    end
    copy_self(e)
  end

  # Text Convert
  def format(code)
    attr_with_key('format') do |fmt|
      str=fmt % code
      @v.msg("Formatted code(#{fmt}) [#{code}] -> [#{str}]",2)
      code=str
    end
    code.to_s
  end

  def text
    attr_with_key('ref') do |r|
      @v.msg("Getting text from ref [#{r}]",2)
      return @var[r] || raise(IndexError,"No reference for [#{r}]")
    end
    @v.msg("Getting text[#{@cn.text}]",2)
    return @cn.text
  end

  def text_convert
    attr_with_key('ref') do |r|
      @v.msg("Getting ref[#{@var[r]}] and text[#{@cn.text}]",2)
      yield @var[r],@cn.text
    end
    @v.msg("Getting text[#{@cn.text}]",2)
    return @cn.text
  end

  def name
    @cn.name
  end
  
  # Private Method
  private
  def copy_self(e)
    d=clone
    d.cn=e
    d
  end

  # Error Handling
  def list_id(xpath)
    @cn.elements.each(xpath+'/[@id]') do |d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    end
  end

end
