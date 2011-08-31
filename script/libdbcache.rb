#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"
require "libdb"

class DbCache < Db
  VarDir="#{ENV['HOME']}/.var/cache"
  XmlDir="#{ENV['HOME']}/ciax-xml"
  def initialize(type,id)
    super
    @v=Verbose.new("cache",2)
    @base="#{type}-#{id}"
    refresh unless id
    @fmar=VarDir+"/#{@base}.mar"
    @fxml=XmlDir+"/#{@base}.xml"
    load
  end

  private
  def refresh
    @v.warn("Db::refresh need to be redefined in child class")
    save
  end

  def load
    if !test(?e,@fmar)
      @v.msg{"MAR file(#@base) not exist"}
    elsif !test(?e,@fxml) || test(?<,@fxml,@fmar)
      hash=Marshal.load(IO.read(@fmar))
      update hash
      @v.msg{"Loaded(#@base)"}
      return self
    else
      @v.msg{["XML file(#@base) updated",
              "cache=#{File::Stat.new(@fmar).mtime}",
              "xml=#{File::Stat.new(@fxml).mtime}"]}
    end
    refresh
    self
  end

  def save
    open(@fmar,'w') {|f|
      f << Marshal.dump(Hash[self])
      @v.msg{"Saved(#@base)"}
    }
    self
  end
end
