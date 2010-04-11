#!/usr/bin/ruby
require "rexml/document"
include REXML
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
      raise("No such a file")
    end
    @title="#{db}/#{type}".upcase
    @prefix=''
    @var=Hash.new
  end

  # Public Method
  public
  def select_id(id)
    begin
      @sel=@doc.elements[TopNode+"//[@id='#{id}']"] || raise
    rescue
      list_id(TopNode+'//select')
      raise("No such a command")
    end
    self
  end

  def [](key)
    a=@doc.attributes[key] || return
    a.to_s
  end

  def node?(xpath)
    e=@doc.elements[TopNode+xpath]
    return unless e
    yield copy_self(e)
    self
  end

  def node_with_text(text)
    @doc.elements.each do |e|
      d=copy_self(e)
      yield d if d.text == text
    end
  end

  def node_with_name(name)
    @doc.elements.each do |e|
      next unless e.name == name
      yield copy_self(e)
    end
  end

  def text_with_attr(key,val)
    @doc.each_element_with_attribute(key,val) do |e|
      return copy_self(e).text
    end
  end

  def each
    @doc.elements.each do |e|
      if e.name == 'select' and @sel
        @sel.elements.each do |s|
          yield copy_self(s)
        end
      else
        yield copy_self(e)
      end
    end
    self
  end

  def attr?(key)
    val=@doc.attributes[key]
    yield val if val
  end

  def attr_to_hash
    h=Hash.new
    @doc.attributes.each do |key,val|
      h[key]=val
    end
    h
  end
  
  def tr_text(code)
    @doc.attributes.each do |key,val|
      case key
      when 'mask'
        code=eval "#{code}#{val}"
      when 'pack'
        code=[code].pack(val)
      when 'unpack'
        code=code.unpack(val).first
      when 'format'
        code=val % code
      end
    end
    code.to_s
  end

  def text
    return @doc.text unless r=@doc.attributes['ref']
    @var[r] || raise("No reference for [#{r}]")
  end

  def name
    @doc.name
  end

  def msg(text='')
    warn mkmsg(text) if ENV['VER']
  end

  def err(text='')
    raise mkmsg(text)
  end

  # Private Method
  private
  def copy_self(e)
    d=clone
    d.doc=e
    d
  end

  def mkmsg(text)
    msg=@doc.attributes['msg']
    msg = msg ? "#{msg} " : ''
    "#{@title}:#{@prefix}#{msg}#{text}".dump
  end

  # Error Handling
  def list_id(xpath)
    @doc.elements.each(xpath+'/[@id]') do |d|
      a=d.attributes
      warn "#{a['id']}\t:#{a['label']}"
    end
  end

end

