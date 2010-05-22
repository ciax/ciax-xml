#!/usr/bin/ruby
require "libverbose"
class XmlDb
  protected
  attr_accessor :cn # Context Node

  def initialize(doc,xpath,title='XMLDB')
    @v=Verbose.new(title)
    @doc=doc
    @cn=doc.elements[xpath] || @v.err("No such Xpath")
  end

  # Public Method
  public
  # Access Node
  def attr
    @cn.attributes
  end

  def text
    @cn.text
  end

  def name
    @cn.name
  end

  #Access Elements
  def each_node(xpath=nil)
    @cn.elements.each(xpath) {|e| yield copy_self(e)}
    self
  end

  def elements(xpath='.')
    copy_self(@cn.elements[xpath])
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

  # Private Method
  private
  def copy_self(e)
    d=clone
    d.cn=e
    d
  end

end
