#!/usr/bin/ruby
require "libverbose"
class XmlDb
  protected
  attr_accessor :cn # Context Node

  def initialize(doc,xpath)
    id=doc.property['id']
    @v=Verbose.new("#{doc.root.name}/#{id}".upcase)
    @var=Hash.new # Use for par,cc
    @property={'id'=>id}
    begin
      @cn=doc.elements[xpath]
    rescue
      p $!
      @v.err("No such Xpath")
    end
  end

  # Public Method
  public
  attr_reader :property

  def set_var!(hash,namespace=nil)
    if namespace
      hash.each {|k,v| @var["#{namespace}:#{k}"]=v}
    else
      @var.update(hash)
    end
    self
  end

  # Access Attributes
  def attr
    @cn.attributes
  end

  #Access Node
  def each_node
    @cn.elements.each {|e| yield copy_self(e)}
    self
  end

  def node_with_text(text)
    @cn.elements.each {|e|
      d=copy_self(e)
      yield d if d.text == text
    }
  end

  def node_with_name(name)
    @cn.elements.each("./#{name}") {|e| yield copy_self(e)}
  end

  def node_with_attr(key,val)
    copy_self(@cn.elements["./[@#{key}='#{val}']"])
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
    @v.msg("Select Node with [#{id}]")
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
    if fmt=@cn.attributes['format'] 
      str=fmt % code
      @v.msg("Format code by (#{fmt}) [#{code}] -> [#{str}]")
      code=str
    end
    code.to_s
  end

  def text
    if r=@cn.attributes['ref']
      @v.msg("Getting text from ref [#{r}]")
      return @var[r] || raise(IndexError,"No reference for [#{r}]")
    end
    @v.msg("Getting text [#{@cn.text}]")
    return @cn.text
  end

  def text_convert
    if r=@cn.attributes['ref']
      @v.msg("Getting ref [#{@var[r]}] and text [#{@cn.text}]")
      yield @var[r],@cn.text
    end
    @v.msg("Getting text [#{@cn.text}]")
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
    @cn.elements.each(xpath+'/[@id]') {|d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    }
  end

end
