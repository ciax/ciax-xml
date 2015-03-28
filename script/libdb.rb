#!/usr/bin/ruby
require "libgetopts"
require "libenumx"
require "libxmldoc"

module CIAX
  # Db class is for read only databases
  # Key for sub structure(Hash,Array) will be symbol (i.e. :data, :list ..)
  # set() generates new individual Db
  # Cache is available
  class Db < Hashx
    XmlDir="#{ENV['HOME']}/ciax-xml"
    attr_reader :cmdlist
    def initialize(type,group=nil)
      super()
      @cls_color=5
      @type=type
      # @cmdlist is CmdList
      @cmdlist=cache(group||'list',group){|doc| doc.cmdlist }
    end

    def set(id)
      raise(InvalidID,"No ID\n"+@list.to_s) unless id
      db=cache(id){|doc|
        puts "Object ID in yield #{doc.object_id}"#
        top=doc.set(id)
        puts "SET (#{id}) OK"#
        doc_to_db(top)
      }
#      deep_copy.update(db)
update(db)
    end

    # cover() will deeply merge self and given db
    # (If end of the element confricts, self content will be taken)
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

    def cache(id,group=nil)
      @base="#{@type}-#{id}"
      if newest?
puts "ENTERING FILE CACHE"
        verbose("#@type/Cache","Loading(#{id})")
        begin
          res=Marshal.load(IO.read(fmar))
        rescue ArgumentError #if empty
          res={}
        end
      else
        warning("#@type/Cache","Refresh Db(#{id})")
puts "XML type=#{@type}, group=#{group.inspect}"#
        @doc||=Xml::Doc.new(@type,group)
puts "Object ID in cache #{@doc.object_id}"#
        res=yield(@doc)
puts "EXIT YIELDED"
        open(fmar,'w') {|f|
          f << Marshal.dump(res)
          verbose("#@type/Cache","Saved(#{id})")
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
