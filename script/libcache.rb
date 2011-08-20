#!/usr/bin/ruby
require "libverbose"
class Cache < Hash
  VarDir="#{ENV['HOME']}/.var"
  XmlDir="#{ENV['HOME']}/ciax-xml"
  def initialize(type,id,&proc)
    @proc=proc
    @v=Verbose.new('CACHE',1)
    @fmar=VarDir+"/#{type}-#{id}.mar"
    @fxml=XmlDir+"/#{type}-#{id}.xml"
    load
  end

  def load
    if !test(?e,@fmar)
      @v.msg{"MAR file not exist"}
      refresh
    elsif test(?<,@fxml,@fmar)
      hash=Marshal.load(IO.read(@fmar))
      update hash
      @v.msg{"Loaded"}
    else
      @v.msg{["XML file updated",@fmar,@fxml]}
      refresh
    end
  end

  def save
    open(@fmar,'w') {|f|
      f << Marshal.dump(Hash[self])
      @v.msg{"Saved"}
    }
  end

  def refresh
    @v.msg{"Refresh"}
    update(@proc.call)
    save
  end

  def to_s
    Verbose.view_struct(self)
  end

  def cover(hash) # override with hash
    replace(rec_merge(self,hash))
  end

  private
  def rec_merge(me,oth)
    me.merge(oth){|k,s,h|
      Hash === h ? rec_merge(s,h) : s
    }
  end
end
