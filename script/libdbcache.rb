#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libdb"

class DbCache < Db
  VarDir="#{ENV['HOME']}/.var/cache"
  XmlDir="#{ENV['HOME']}/ciax-xml"
  def initialize(type,id)
    @v=Verbose.new("cache",2)
    @base="#{type}-#{id}"
    @type=type
    @id=id || refresh
    @fmar=VarDir+"/#{@base}.mar"
    @fxml=XmlDir+"/#{@base}.xml"
    load
  end

  private
  def load
    if !test(?e,@fmar)
      @v.msg{"MAR file(#{@base}) not exist"}
      refresh
      save
    elsif !test(?e,@fxml) || test(?<,@fxml,@fmar)
      hash=Marshal.load(IO.read(@fmar))
      update hash
      @v.msg{"Loaded(#{@base})"}
    else
      @v.msg{["XML file(#{@base}) updated",
              "cache=#{File::Stat.new(@fmar).mtime}",
              "xml=#{File::Stat.new(@fxml).mtime}"]}
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
