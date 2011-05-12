#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libmodsym"

class ObjDb
  include ModSym
  attr_reader :alias,:list,:label,:symbol,:table,:group
  def initialize(obj)
    doc=XmlDoc.new('odb',obj)
    @v=Verbose.new("odb/#{doc['id']}",2)
    @doc=doc
    @alias={}
    @list={}
    @label={}
    @symbol={}
    @group={}
    init_command
    init_stat
    @table=init_sym
  end

  def override(obj)
    case obj
    when Label
      @label.each{|k,v|
        next unless obj.key?(k)
        obj[k]['label']=v
      }
    end
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
      if symbol=hash.delete('symbol')
        @symbol[id]=symbol
        @v.msg{"SYMBOL:[#{id}] : #{symbol}"}
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
