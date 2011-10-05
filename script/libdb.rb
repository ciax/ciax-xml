#!/usr/bin/ruby
require "libmsg"
require "libexhash"
require "libxmldoc"

class Db < ExHash
  XmlDir="#{ENV['HOME']}/ciax-xml"
  def initialize(type)
    @v=Msg::Ver.new(type,5)
    @type=type
  end

  def cache(id,nocache=nil)
    base="#{@type}-#{id}"
    fmar=VarDir+"/cache/#{base}.mar"
    fxml=XmlDir+"/#{base}.xml"
    unless nocache
      if !test(?e,fmar)
        @v.msg{"CACHE:MAR file(#{base}) not exist"}
      elsif test(?e,fxml) && test(?>,fxml,fmar)
        @v.msg{["CACHE:XML file(#{base}) updated",
                "cache=#{File::Stat.new(fmar).mtime}",
                "xml=#{File::Stat.new(fxml).mtime}"]}
      else
        update(Marshal.load(IO.read(fmar)))
        @v.msg{"CACHE:Loaded(#{base})"}
        return self
      end
    end
    yield XmlDoc.new(@type,id)
    open(fmar,'w') {|f|
      f << Marshal.dump(Hash[self])
      @v.msg{"CACHE:Saved(#{base})"}
    }
    self
  end

  def path(ary)
    ary.inject(self){|d,s| d[s.to_sym]}
  end
end
