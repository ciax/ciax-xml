#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libxmldoc"
require "find"

class Db < ExHash
  XmlDir="#{ENV['HOME']}/ciax-xml"
  extend Msg::Ver
  attr_reader :list
  def initialize(type,id=nil)
    Db.init_ver("cache/#{type}",5)
    @type=type
    @list=cache('list'){|doc| doc.list }
    @list.error unless id
    update(cache(id){|doc| yield doc.set(id) }).deep_freeze
  end

  private
  def cache(id)
    base="#{@type}-#{id}"
    fmar=VarDir+"/cache/#{base}.mar"
    if ENV['NOCACHE']
      Db.msg{"ENV NOCACHE is set"}
    elsif !test(?e,fmar)
      Db.msg{"MAR file(#{base}) not exist"}
    elsif newer=Find.find(XmlDir+'/'){|f|
        break f if File.file?(f) && test(?>,f,fmar)
      }
      Db.msg{["File(#{newer}) is newer than cache",
              "cache=#{File::Stat.new(fmar).mtime}",
              "file=#{File::Stat.new(newer).mtime}"]}
    else
      Db.msg{"Loaded(#{base})"}
      return Marshal.load(IO.read(fmar))
    end
    res=Msg.type?(yield(XmlDoc.new(@type)),Hash)
    open(fmar,'w') {|f|
      f << Marshal.dump(res)
      Db.msg{"Saved(#{base})"}
    }
    res
  end

  def cover(db)
    Msg.type?(db,Db)
    db.deep_copy.deep_update(self).deep_freeze
  end
end
