#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libxmldoc"

class Db < ExHash
  XmlDir="#{ENV['HOME']}/ciax-xml"
  attr_reader :list
  def initialize(type,group=nil)
    init_ver(type,5)
    @type=type
    @group=group
    @list=cache(group||'list',group){|doc| doc.list }
  end

  def set(id)
    @list.error unless id
    update(cache(id,@group){|doc| doc_to_db doc.set(id) }).deep_copy
  end

  private
  def doc_to_db(doc)
    {}
  end

  def cache(id,group)
    @base="#{@type}-#{id}"
    if newest?
      verbose{"Cache:Loading(#{@base})"}
      begin
        res=Marshal.load(IO.read(fmar))
      rescue ArgumentError #if empty
        res={}
      end
    else
      verbose{"Cache:Refresh Db"}
      res=Msg.type?(yield(Xml::Doc.new(@type,group)),Hash)
      open(fmar,'w') {|f|
        f << Marshal.dump(res)
        verbose{"Cache:Saved(#{@base})"}
      }
    end
    res
  end

  def cover(db,key=nil,depth=nil)
    Msg.type?(db,Db)
    if key
      self[key]=db.deep_copy.deep_update(self[key]||{},depth)
    else
      db.deep_copy.deep_update(self,depth)
    end
  end


  def newest?
    if ENV['NOCACHE']
      verbose{"ENV NOCACHE is set"}
    elsif !test(?e,fmar)
      verbose{"MAR file(#{@base}) not exist"}
    elsif newer=cmp($".grep(/#{ScrDir}/)+Dir.glob(XmlDir+"/#{@type}-*.xml"))
      verbose{["File(#{newer}) is newer than cache",
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

  def set_par(e,id,db)
    case e.name
    when 'par_num'
      attr={:type => 'num',:list => e.text.split(',')}
      ((db[:parameter]||={})[id]||=[]) << attr
    when 'par_reg'
      attr={:type => 'reg',:list => e.text.split(',')}
      ((db[:parameter]||={})[id]||=[]) << attr
    else
      nil
    end
  end
end
