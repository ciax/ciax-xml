#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libxmldoc"
require "find"

class Db < ExHash
  XmlDir="#{ENV['HOME']}/ciax-xml"
  attr_reader :list
  def initialize(type,id=nil)
    @v=Msg::Ver.new(type,5)
    @type=type
    @list=cache('list'){|doc| doc.list }
    return unless id
    update(cache(id){|doc| yield doc.set(id) }).deep_freeze
  end

  private
  def cache(id)
    base="#{@type}-#{id}"
    fmar=VarDir+"/cache/#{base}.mar"
    if ENV['NOCACHE']
      @v.msg{"CACHE:ENV NOCACHE is set"}
    elsif !test(?e,fmar)
      @v.msg{"CACHE:MAR file(#{base}) not exist"}
    elsif newer=Find.find(XmlDir+'/'){|f|
        break f if File.file?(f) && test(?>,f,fmar)
      }
      @v.msg{["CACHE:File(#{newer}) is newer than cache",
              "CACHE:cache=#{File::Stat.new(fmar).mtime}",
              "CACHE:file=#{File::Stat.new(newer).mtime}"]}
    else
      @v.msg{"CACHE:Loaded(#{base})"}
      return Marshal.load(IO.read(fmar))
    end
    res=Msg.type?(yield(XmlDoc.new(@type)),Hash)
    open(fmar,'w') {|f|
      f << Marshal.dump(res)
      @v.msg{"CACHE:Saved(#{base})"}
    }
    res
  end

  def cover(db)
    Msg.type?(db,Db)
    db.deep_copy.deep_update(self).deep_freeze
  end
end
