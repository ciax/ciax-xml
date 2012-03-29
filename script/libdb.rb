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
    view=hash.dup
    view.each{|k,v|
      case v
      when Hash
        view[k]='HASH'
      end
    } if Hash === view
    Msg.view_struct(view)
  end

  private
  def cache(id)
    base="#{@type}-#{id}"
    fmar=VarDir+"/cache/#{base}.mar"
    if !test(?e,fmar)
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
      return freeze
    end
    yield XmlDoc.new(@type,id)
    open(fmar,'w') {|f|
      f << Marshal.dump(Hash[self])
      @v.msg{"CACHE:Saved(#{base})"}
    }
    deep_freeze(self)
  end

  def cover(db)
    Msg.type?(db,Db)
    deep_freeze(db.dup.deep_update(self))
  end

  def deep_freeze(db)
    case db
    when Hash
      db.keys.each{|i| deep_freeze(db[i])}
    when Array
      db.size.times{|i| deep_freeze(db[i])}
    end
    db.freeze
  end
end
