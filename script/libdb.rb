#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libsymdb"

class Db < Hash
  attr_reader :command,:status,:tables
  def initialize(type,id)
    @doc=XmlDoc.new(type,id)
    @v=Verbose.new("#{type}/#{@doc['id']}",2)
    update(@doc)
    @command={}
    @status={}
    @tables=SymDb.new(@doc)
    @v.msg{"Structure:tables #{@tables}"}
  end

  def to_s
    str=view_struct("Command",@command)
    str << view_struct("Status",@status)
    str << view_struct("SymTable",@tables)
  end

  private
  def view_struct(key,val,indent=0)
    str="  " * indent
    if Hash === val
      str << ("%-4s :\n" % key)
      val.each{|k,v|
        str << view_struct(k,v,indent+1)
      }
    elsif Array === val
      str << ("%-4s :\n" % key)
      val.each_with_index{|v,i|
        str << view_struct("[#{i}]",v,indent+1)
      }
    else
      str << ("%-4s : %s\n" % [key,val])
    end
    str
  end
end
