#!/usr/bin/ruby
require "libmsg"
require "libvar"

# Should be included ExHash object
# Read/Write JSON file
# Need @type
module InFile
  def self.extended(obj)
    Msg.type?(obj,Var)
  end

  def init(id)
    self['id']=@id=id
    @dir="/json/"
    @base=@type+'_'+id
    @prefix=VarDir
    self
  end

  def load(tag=nil)
    begin
      open(fname(tag)){|f|
        json_str=f.read
        if json_str.empty?
          Msg.warn(" -- json file is empty")
        else
          super(json_str)
        end
      }
    rescue Errno::ENOENT
      if tag
        raise UserError,"Tag=#{taglist}"
      else
        Msg.warn("  -- no json file (#{fname})")
      end
    end
    self
  end

  private
  def fname(tag=nil)
    base=[@type,@id,tag].compact.join('_')
    @prefix+@dir+base+".json"
  end

  def taglist
    Dir.glob(fname('*')).map{|f|
        f.slice(/.+_(.+)\.json/,1)
    }.sort
  end
end

module InUrl
  require "open-uri"
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
      f << (data ? JSON.dump(data) : to_j)
    }
    if tag
      # Making 'latest' tag link
      sname=fname('latest')
      File.unlink(sname) if File.symlink?(sname)
      File.symlink(fname(tag),sname)
      @v.msg{"Symboliclink to [#{sname}]"}
    end
    self
  end
end
