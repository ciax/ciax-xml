#!/usr/bin/ruby
require 'libgetopts'
require 'libenumx'
require 'libxmldoc'

module CIAX
  XmlDir = "#{ENV['HOME']}/ciax-xml"
  PROJ = ENV['PROJ'] || 'moircs'
  # Db class is for read only databases, which holds all items of database.
  # Key for sub structure(Hash,Array) will be symbol (i.e. :data, :list ..)
  # set() generates HashDb
  # Cache is available
  class Dbi < Hashx # DB Item
    # cover() will deeply merge self and given db
    # (If end of the element confricts, self content will be taken)
    def cover(db, key = nil, depth = nil)
      type?(db, Dbi)
      if key
        self[key] = db.deep_copy.deep_update(self[key] || {}, depth)
      else
        db.deep_copy.deep_update(self, depth)
      end
    end
  end

  class Db < Hashx
    attr_reader :displist
    def initialize(type, proj = nil)
      super()
      @cls_color = 5
      @type = type
      @proj = proj
      # @displist is Disp::List
      lid = 'list'
      lid += "-#{@proj}" if @proj
      @displist = cache(lid, &:displist)
    end

    def get(id)
      raise(InvalidID, "No such ID (#{id}) in #{@type}\n" + @displist.to_s) unless @displist.key?(id)
      cache(id) do|doc|
        doc_to_db(doc.set(id))
      end
    end

    private
    # Returns Hash
    def doc_to_db(_)
      Dbi.new
    end

    def cache(id)
      @base = "#{@type}-#{id}"
      @marfile = vardir('cache') + "#{@base}.mar"
      if newest?
        verbose { "Cache Loading (#{id})" }
        return self[id] if key?(id)
        begin
          res = Marshal.load(IO.read(@marfile))
        rescue ArgumentError # if empty
          res = {}
        end
      else
        warning("Cache Refresh (#{id})")
        res = yield(@doc ||= Xml::Doc.new(@type, @proj))
        open(@marfile, 'w') do|f|
          f << Marshal.dump(res)
          verbose { "Cache Saved(#{id})" }
        end
      end
      self[id] = res
    end

    def newest?
      if ENV['NOCACHE']
        verbose { "#{@type}/Cache ENV NOCACHE is set" }
        return false
      elsif !test(?e, @marfile)
        verbose { "#{@type}/Cache MAR file(#{@base}) not exist" }
        return false
      else
        newer = cmp($".grep(/#{ScrDir}/) + Dir.glob(XmlDir + "/#{@type}-*.xml"))
        if newer
          verbose { "#{@type}/Cache File(#{newer}) is newer than cache" }
          verbose { "#{@type}/Cache cache=#{::File::Stat.new(@marfile).mtime}" }
          verbose { "#{@type}/Cache file=#{::File::Stat.new(newer).mtime}" }
          return false
        end
      end
      true
    end

    def cmp(ary)
      ary.each do|f|
        return f if ::File.file?(f) && test(?>, f, @marfile)
      end
      false
    end

    def par2item(e, item)
      case e.name
      when 'par_num'
        attr = { :type => 'num', :list => e.text.split(',') }
        attr['label'] = e['label'] if e['label']
        (item[:parameters] ||= []) << attr
      when 'par_str'
        attr = { :type => 'str', :list => e.text.split(',') }
        attr['label'] = e['label'] if e['label']
        (item[:parameters] ||= []) << attr
      else
        nil
      end
    end
  end
end
