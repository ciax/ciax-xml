#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libsymdb"

class ObjDb < Hash
  def initialize(obj,db={})
    update(db)
    doc=XmlDoc.new('odb',obj)
    @v=Verbose.new("odb/#{doc['id']}",2)
    @doc=doc
    init_command(self[:command])
    init_stat(self[:status])
    self[:symtbl].update(SymDb.new(doc))
  rescue SelectID
  end

  private
  def init_command(db)
    @doc.find_each('command','alias'){|e0|
      e0.attr2db(db){|v|v}
    }
  end

  def init_stat(db)
    @doc.find_each('status','title'){|e0|
      e0.attr2db(db,'ref'){|v|v}
    }
  end
end
