#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libsymdb"

class ObjDb
  attr_reader :alias,:list,:label,:symref,:table,:group
  def initialize(obj)
    @alias={}
    @list={}
    @label={}
    @symref={}
    @group={}
    @table={}
    doc=XmlDoc.new('odb',obj)
    @v=Verbose.new("odb/#{doc['id']}",2)
    @doc=doc
    init_command
    init_stat
    @table=SymDb.new(doc)
  rescue SelectID
  end

  private
  def init_command
    @doc.find_each('command','alias'){|e0|
      hash=e0.to_h
      id=hash['id']      
      ref=hash['ref']||id
      @alias[id]=ref
      @list[id]=hash['label']
      @v.msg{"Alias:[#{id}](#{ref}):#{label}"}
    }
  end

  def init_stat
    @doc.find_each('status','title'){|e0|
      hash=e0.to_h
      id=hash.delete('ref')
      if symref=hash.delete('symbol')
        @symref[id]=symref
        @v.msg{"SYMREF:[#{id}] : #{symref}"}
      end
      if label=hash.delete('label')
        @label[id]=label
        @v.msg{"LABEL:[#{id}] : #{label}"}
      end
      if group=hash.delete('group')
        @group[id]=group
        @v.msg{"GROUP:[#{id}] : #{group}"}
      end
    }
    self
  end
end
