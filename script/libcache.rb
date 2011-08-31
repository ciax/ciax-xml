#!/usr/bin/ruby
require "libverbose"
require "libxmldoc"

class Cache < Hash
  VarDir="#{ENV['HOME']}/.var/cache"
  XmlDir="#{ENV['HOME']}/ciax-xml"
  def initialize(type,id,nocache=nil)
    @v=Verbose.new("cache",2)
    base="#{type}-#{id}"
    fmar=VarDir+"/#{base}.mar"
    fxml=XmlDir+"/#{base}.xml"
    unless nocache
      if !test(?e,fmar)
        @v.msg{"MAR file(#{base}) not exist"}
      elsif test(?e,fxml) && test(?>,fxml,fmar)
        @v.msg{["XML file(#{base}) updated",
                "cache=#{File::Stat.new(fmar).mtime}",
                "xml=#{File::Stat.new(fxml).mtime}"]}
      else
        update(Marshal.load(IO.read(fmar)))
        @v.msg{"Loaded(#{base})"}
        return
      end
    end
    open(fmar,'w') {|f|
      f << Marshal.dump(update(yield XmlDoc.new(type,id)))
      @v.msg{"Saved(#{base})"}
    }
  end
end

