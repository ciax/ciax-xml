#!/usr/bin/ruby
require "libmsg"
require "libxmldoc"

module ModCache
  VarDir="#{ENV['HOME']}/.var/cache"
  XmlDir="#{ENV['HOME']}/ciax-xml"
  def cache(type,id,nocache=nil)
    @v=Msg::Ver.new("cache",2)
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
        return self
      end
    end
    yield XmlDoc.new(type,id)
    open(fmar,'w') {|f|
      f << Marshal.dump(Hash[self])
      @v.msg{"Saved(#{base})"}
    }
    self
  end

  def to_s
    Msg.view_struct(self)
  end
end
