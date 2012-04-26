#!/usr/bin/ruby
require "libmsg"
require "json"
require "open-uri"
require "libexenum"

# Should be included ExHash object
# Read/Write JSON file
# Need self['type']
module InFile
  def self.extended(obj)
    Msg.type?(obj,ExHash)
  end

  def init(id)
    self['id']=id
    @dir="/json/"
    @base=self['type']+'_'+id
    @prefix=VarDir
    self
  end

  def load(tag=nil)
    begin
      open(fname(tag)){|f|
        str=f.read
        if str.empty?
          Msg.warn(" -- json file is empty")
        else
          deep_update(JSON.load(str))
        end
      }
    rescue
      if tag
        raise UserError,"Tag=#{taglist}"
      else
        Msg.warn("  -- no json file (#{fname})")
      end
    end
    self
  end

  private
  def fname(tag)
    base=[self['type'],self['id'],tag].compact.join('_')
    @prefix+@dir+base+".json"
  end

  def taglist
    Dir.glob(fname('*')).map{|f|
        f.slice(/.+_(.+)\.json/,1)
    }
  end
end

module InUrl
  include InFile
  def init(id,host='')
    super(id)
    @prefix="http://"+host
    self
  end
end

module IoFile
  include InFile
  def save(data=nil,tag=nil)
    name=fname(tag)
    open(name,'w'){|f|
      f << JSON.dump(data||to_hash)
    }
    if tag
      # Making 'latest' tag link
      sname=fname('latest')
      File.unlink(sname) if File.exist?(sname)
      File.symlink(fname(tag),sname)
      @v.msg{"Symboliclink to [#{sname}]"}
    end
    self
  end
end
