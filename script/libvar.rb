#!/usr/bin/ruby
require "libmsg"
require "libexenum"

class Var < ExHash
  attr_reader :type,:id,:ver,:val
  def initialize(type)
    super()
    self['type']=@type=type
    self.val=Hash.new
    set_time
  end

  def upd
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
    extend Msg::Ver
    def self.extended(obj)
      init_ver('Load',12)
      Msg.type?(obj,Var)
    end
    def init(db)
      @db=Msg.type?(db,Db)
      self.id=db['id']||Msg.cfg_err("No ID")
      @dir="/json/"
      @base=@type+'_'+id
      @prefix=VarDir
      self
    end
    def load(tag=nil)
      begin
        Load.msg{"Loading #{fname(tag)}"}
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
          Msg.par_err("No such Tag","Tag=#{taglist}")
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

  module Url
    require "open-uri"
    def self.extended(obj)
      Msg.type?(obj,Load)
    end
    def init(host)
      host||='localhost'
      @prefix="http://"+host
      self
    end
  end

  module Save
    extend Msg::Ver
    def self.extended(obj)
      init_ver('Save',12)
      Msg.type?(obj,Load)
    end
    def save(data=nil,tag=nil)
      name=fname(tag)
      open(name,'w'){|f|
        f << (data ? JSON.dump(data) : to_j)
      }
      Save.msg{"[#{@base}] is Saved"}
      if tag
        # Making 'latest' tag link
        sname=fname('latest')
        File.unlink(sname) if File.symlink?(sname)
        File.symlink(fname(tag),sname)
        Save.msg{"Symboliclink to [#{sname}]"}
      end
      self
    end
  end
end
