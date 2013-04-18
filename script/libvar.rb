#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libupdate"
require "libelapse"

class Var < ExHash
  def initialize(type)
    super()
    self['type']=type
  end

  ## Read/Write JSON file
  def ext_file(id)
    extend File
    ext_file(id)
    self
  end

  def ext_url(host=nil)
    extend Url
    ext_url(host)
    self
  end

  def ext_save
    extend(Save).init_ver('VarSave',12)
    self
  end

  class Upd < Var
    # @ elapsed,upd_proc*
    attr_reader :elapsed,:upd_proc
    def initialize(type)
      super
      set_time
      self['val']=ExHash.new
      @upd_proc=UpdProc.new
    end

    def set_time(time=nil)
      self['time']=time||Sec.new
      @elapsed=Elapse.new(self['time'])
      self
    end

    def upd
      @upd_proc.upd
      self
    end

    def get(key)
      self['val'][key]
    end

    # Update with str (key=val,key=val,..)
    def str_update(str)
      Msg.type?(str,String)
      str.split(',').each{|i|
        k,v=i.split('=')
        self['val'][k]=v
      }
      set_time
      self
    end

    def unset(key)
      self['val'].delete(key)
    end
  end

  module File
    # @< upd_proc*
    # @ db,base,prefix
    def self.extended(obj)
      Msg.type?(obj,Var)
    end

    def ext_file(id)
      init_ver('VarFile',12)
      self['id']=id||Msg.cfg_err("ID")
      @base=self['type']+'_'+self['id']+'.json'
      @prefix=VarDir
      self
    end

    def load(tag=nil)
      name=fname(tag)
      json_str=''
      open(name){|f|
        verbose{"Loading [#{@base}](#{f.size})"}
        json_str=f.read
      }
      if json_str.empty?
        Msg.warn(" -- json file (#{@base}) is empty")
      else
        super(json_str)
        self['time']=Sec.parse(self['time']) if key?('time')
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
      @base=[self['type'],self['id'],tag].compact.join('_')+'.json'
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
    # @<< (upd_proc*)
    # @< base,prefix
    def self.extended(obj)
      Msg.type?(obj,File)
    end

    def ext_url(host)
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
    # @<< (upd_proc*)
    # @< base,prefix
    def self.extended(obj)
      Msg.type?(obj,File)
    end

    def save(data=nil,tag=nil)
      name=fname(tag)
      open(name,'w'){|f|
        f.flock(Object::File::LOCK_EX)
        f << (data ? JSON.dump(data) : to_j)
        verbose{"[#{@base}](#{f.size}) is Saved"}
      }
      if tag
        # Making 'latest' tag link
        sname=fname('latest')
        Object::File.unlink(sname) if Object::File.symlink?(sname)
        Object::File.symlink(name,sname)
        verbose{"Symboliclink to [#{sname}]"}
      end
      self
    end
  end
end
