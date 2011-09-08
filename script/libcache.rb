#!/usr/bin/ruby
require "libmsg"
require "libxmldoc"

module Cache
  VarDir="#{ENV['HOME']}/.var/cache"
  XmlDir="#{ENV['HOME']}/ciax-xml"
  def cache(type,id,nocache=nil)
    @v=Msg.new("cache",2)
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
    hash=yield XmlDoc.new(type,id)
    open(fmar,'w') {|f|
      f << Marshal.dump(hash)
      update(hash)
      @v.msg{"Saved(#{base})"}
    }
    mklist
    self
  end

  def mklist
    if key?(:command)
      cmd=self[:command]
      @cv=CmdList.new("== Command List ==").add(cmd[:label])
    end
    self
  end

  def to_s
    @cv.to_s
  end
end
