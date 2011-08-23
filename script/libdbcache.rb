#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libdb"

class DbCache < Db
  VarDir="#{ENV['HOME']}/.var/cache"
  XmlDir="#{ENV['HOME']}/ciax-xml"
  def initialize(type,id)
    @type=type
    @id=id
    @fmar=VarDir+"/#{type}-#{id}.mar"
    @fxml=XmlDir+"/#{type}-#{id}.xml"
    @v=Verbose.new("cache",2)
    load
  end

  def load
    if !test(?e,@fmar)
      @v.msg{"MAR file not exist"}
      refresh
      save
    elsif test(?<,@fxml,@fmar)
      hash=Marshal.load(IO.read(@fmar))
      update hash
      @v.msg{"Loaded"}
    else
      @v.msg{["XML file updated",@fmar,@fxml]}
      refresh
      save
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
    XmlDoc.new(@type,@id)
  end
end
