#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libxmldoc"

class Db < ExHash
  extend Msg::Ver
  XmlDir="#{ENV['HOME']}/ciax-xml"
  attr_reader :list
  def initialize(type,id=nil,group=nil)
    Db.init_ver("Cache/%s",5,self)
    @type=type
    @list=cache(group||'list',group){|doc| doc.list }
    @list.error unless id
    update(cache(id,group){|doc| yield doc.set(id) }).deep_freeze
  end

  private
  def cache(id,group)
    @base="#{@type}-#{id}"
    if newest?
      Db.msg{"Loading(#{@base})"}
      res=Marshal.load(IO.read(fmar))
    else
      Db.msg{"Making Db"}
      res=Msg.type?(yield(Xml::Doc.new(@type,group)),Hash)
      open(fmar,'w') {|f|
        f << Marshal.dump(res)
        Db.msg{"Saved(#{@base})"}
      }
    end
    res
  end

  def cover(db)
    Msg.type?(db,Db)
    db.deep_copy.deep_update(self).deep_freeze
  end


  def newest?
    if ENV['NOCACHE']
      Db.msg{"ENV NOCACHE is set"}
    elsif !test(?e,fmar)
      Db.msg{"MAR file(#{base}) not exist"}
    elsif newer=cmp($".grep(/#{ScrDir}/)+Dir.glob(XmlDir+"/#{@type}-*.xml"))
      Db.msg{["File(#{newer}) is newer than cache",
              "cache=#{File::Stat.new(fmar).mtime}",
              "file=#{File::Stat.new(newer).mtime}"]
      }
    else
      return true
    end
    false
  end

  def cmp(ary)
    ary.each{|f|
      return f if File.file?(f) && test(?>,f,fmar)
    }
    false
  end

  # Generate File Name
  def fmar
    VarDir+"/cache/#{@base}.mar"
  end
end
