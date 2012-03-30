#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libxmldoc"
require "find"

class Db < ExHash
  XmlDir="#{ENV['HOME']}/ciax-xml"
  def initialize(type)
    @v=Msg::Ver.new(type,5)
    @type=type
  end

  def path(ary=[])
    hash=ary.inject(self){|prev,a|
      prev[a.to_sym]
    }
    stat=hash.dup
    stat.each{|k,v|
      case v
      when Hash
        stat[k]='HASH'
      end
    } if Hash === stat
    Msg.view_struct(stat)
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
      update(Marshal.load(IO.read(fmar)))
      @v.msg{"CACHE:Loaded(#{base})"}
      return deep_freeze
    end
    yield XmlDoc.new(@type,id)
    open(fmar,'w') {|f|
      f << Marshal.dump(Hash[self])
      @v.msg{"CACHE:Saved(#{base})"}
    }
    deep_freeze
  end

  def cover(db)
    Msg.type?(db,Db)
    db.deep_copy.deep_update(self).deep_freeze
  end
end
