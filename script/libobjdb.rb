#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libsymdb"

class ObjDb < Hash
  attr_reader :alias,:list
  def initialize(obj,db={})
    update(db)
    @alias={}
    @list={}
    doc=XmlDoc.new('odb',obj)
    @v=Verbose.new("odb/#{doc['id']}",2)
    @doc=doc
    init_command
    init_stat
    self[:symtbl].update(SymDb.new(doc))
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
      [:symbol,:label,:group].each{|k|
        self[k]={} unless key?(k)
        if d=hash[k.to_s]
          self[k][id]=d
          @v.msg{k.to_s.upcase+":[#{id}] : #{k}"}
        end
      }
    }
    self
  end
end
