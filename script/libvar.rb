#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libupdate"

class Var < ExHash
  # @ id*,ver*,val*,upd_proc*
  attr_reader :id,:ver,:val,:upd_proc
  def initialize(type)
    super()
    self['type']=type
    self.val=Hash.new
    set_time
    @upd_proc=Update.new
  end

  def upd
    @upd_proc.upd
    self
  end

  def get(key)
    @val[key]
  end

  # Update with str (key=val,key=val,..)
  def str_update(str)
    Msg.type?(str,String)
    str.split(',').each{|i|
      k,v=i.split('=')
      @val[k]=v
    }
    set_time
    self
  end

  def unset(key)
    @val.delete(key)
  end

  def id=(id)
    self['id']=@id=id
  end

  # Version Number
  def ver=(ver)
    self['ver']=@ver=ver
  end

  def val=(val)
    self['val']=@val=val
    def val.to_s
      Msg.view_struct(self,'val')
    end
  end

  def set_time(time=nil)
    @val['time']=time||Msg.now
    self
  end

  def load(json_str=nil)
    super
    bind_var
    self
  end

  private
  def bind_var
    ['type','id','ver','val'].each{|k|
      eval "@#{k}=self['#{k}']"
    }
  end

  ## Read/Write JSON file
  public
  def ext_file(db)
    extend Load
    init(db)
    self
  end

  def ext_url(host=nil)
    extend Url
    init(host)
    self
  end

  def ext_save
    extend Save
    self
  end

  module Load
    # @< (type*),id*,ver*,val*
    # @ db,base,prefix
    extend Msg::Ver
    def self.extended(obj)
      init_ver('VarLoad',12)
      Msg.type?(obj,Var)
    end

    def init(db)
      @db=Msg.type?(db,Db)
      self.id=db['site']||Msg.cfg_err("No SITE ID")
      @base=self['type']+'_'+id+'.json'
      @prefix=VarDir
      self
    end

    def load(tag=nil)
      name=fname(tag)
      json_str=''
      open(name){|f|
        Load.msg{"Loading [#{@base}](#{f.size})"}
        json_str=f.read
      }
      if json_str.empty?
        Msg.warn(" -- json file (#{@base}) is empty")
      else
        super(json_str)
      end
      self
    rescue Errno::ENOENT
      if tag
        Msg.par_err("No such Tag","Tag=#{taglist}")
      else
        Msg.warn("  -- no json file (#{@base})")
      end
      self
    end

    private
    def fname(tag=nil)
      @base=[self['type'],@id,tag].compact.join('_')+'.json'
      @prefix+"/json/"+@base
    end

    def taglist
      Dir.glob(fname('*')).map{|f|
        f.slice(/.+_(.+)\.json/,1)
      }.sort
    end
  end

  module Url
    require "open-uri"
    # @<< type*,id*,ver*,val*
    # @< db,base,prefix
    def self.extended(obj)
      Msg.type?(obj,Load)
    end

    def init(host)
      host||='localhost'
      @prefix="http://"+host
      self
    end

    def load(tag=nil)
      super
    rescue OpenURI::HTTPError
      Msg.warn("  -- no url file (#{fname})")
      self
    end
  end

  module Save
    extend Msg::Ver
    # @<< type*,id*,ver*,val*
    # @< db,base,prefix
    def self.extended(obj)
      init_ver('VarSave',12)
      Msg.type?(obj,Load)
    end

    def save(data=nil,tag=nil)
      name=fname(tag)
      open(name,'w'){|f|
        f.flock(File::LOCK_EX)
        f << (data ? JSON.dump(data) : to_j)
        Save.msg{"[#{@base}](#{f.size}) is Saved"}
      }
      if tag
        # Making 'latest' tag link
        sname=fname('latest')
        File.unlink(sname) if File.symlink?(sname)
        File.symlink(name,sname)
        Save.msg{"Symboliclink to [#{sname}]"}
      end
      self
    end
  end
end
