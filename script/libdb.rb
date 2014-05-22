#!/usr/bin/ruby
require "libgetopts"
require "libenumx"
require "libxmldoc"

module CIAX
  class Db < Hashx
    XmlDir="#{ENV['HOME']}/ciax-xml"
    attr_reader :list
    def initialize(type,group=nil)
      @ver_color=5
      @type=type
      @group=group
      @list=cache(group||'list',group){|doc| doc.list }
    end

    def set(id)
      raise(InvalidID,"No such ID(#{id})\n"+@list.to_s) unless id
      deep_copy.update(cache(id,@group){|doc| doc_to_db doc.set(id) })
    end

    def cover(db,key=nil,depth=nil)
      type?(db,Db)
      if key
        self[key]=db.deep_copy.deep_update(self[key]||{},depth)
      else
        db.deep_copy.deep_update(self,depth)
      end
    end

    private
    def doc_to_db(doc)
      {}
    end

    def cache(id,group)
      @base="#{@type}-#{id}"
      if newest?
        verbose("#@type/Cache","Loading(#{@base})")
        begin
          res=Marshal.load(IO.read(fmar))
        rescue ArgumentError #if empty
          res={}
        end
      else
        verbose("#@type/Cache","Refresh Db")
        res=type?(yield(Xml::Doc.new(@type,group)),Hash)
        open(fmar,'w') {|f|
          f << Marshal.dump(res)
          verbose("#@type/Cache","Saved(#{@base})")
        }
      end
      res
    end

    def newest?
      if ENV['NOCACHE']
        verbose("#@type/Cache","ENV NOCACHE is set")
      elsif !test(?e,fmar)
        verbose("#@type/Cache","MAR file(#{@base}) not exist")
      elsif newer=cmp($".grep(/#{ScrDir}/)+Dir.glob(XmlDir+"/#{@type}-*.xml"))
        verbose("#@type/Cache","File(#{newer}) is newer than cache")
        verbose("#@type/Cache","cache=#{::File::Stat.new(fmar).mtime}")
        verbose("#@type/Cache","file=#{::File::Stat.new(newer).mtime}")
      else
        return true
      end
      false
    end

    def cmp(ary)
      ary.each{|f|
        return f if ::File.file?(f) && test(?>,f,fmar)
      }
      false
    end

    # Generate File Name
    def fmar
      dir=VarDir+"/cache/"
      FileUtils.mkdir_p dir
      dir+"#{@base}.mar"
    end

    def par2item(e,item)
      case e.name
      when 'par_num'
        attr={:type => 'num',:list => e.text.split(',')}
        (item[:parameters]||=[]) << attr
      when 'par_str'
        attr={:type => 'str',:list => e.text.split(',')}
        (item[:parameters]||=[]) << attr
      else
        nil
      end
    end
  end
end
