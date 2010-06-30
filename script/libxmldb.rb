#!/usr/bin/ruby
require "libverbose"
class XmlDb
  protected
  attr_accessor :cn # Context Node

  def initialize(doc,xpath,title='XMLDB')
    @v=Verbose.new(title)
    @doc=doc
    @v.err(@cn=doc.elements[xpath]){"No such Xpath"}
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
    e=@cn.elements[xpath] || raise("No XPath")
    copy_self(e)
  end

  def next_node! # Node pick up for macro
    @cn=@cn.next_element
    self
  end

  # Text Convert
  def format(code)
    if fmt=@cn.attributes['format'] 
      str=fmt % code.to_i
      @v.msg{"Format code by (#{fmt}) [#{code}] -> [#{str}]"}
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
