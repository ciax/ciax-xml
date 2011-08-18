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
end
