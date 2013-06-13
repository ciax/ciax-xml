#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libupdate"

class Var < ExHash # Including 'type'
  def initialize(type)
    super()
    self['type']=type
  end

  def ext_upd
    extend Upd
    ext_upd
    self
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
    extend(Save)
    self
  end

  module Upd # Including 'time'
    attr_reader :upd_proc
    def self.extended(obj)
      Msg.type?(obj,Var)
    end

    def ext_upd
      self['time']=UnixTime.now
      self['val']=ExHash.new
      @upd_proc=[] # Proc Array
    end

    def upd # update after processing
      @upd_proc.each{|p| p.call(self)}
      self
    end

    def load(json_str=nil)
      super
      self['time']=UnixTime.parse(self['time']) if key?('time')
      upd
    end

    # Update with str (key=val,key=val,..)
    def str_update(str)
      Msg.type?(str,String)
      str.split(',').each{|i|
        k,v=i.split('=')
        self['val'][k]=v
      }
      self['time']=UnixTime.now
      upd
    end

    def unset(key)
      self['val'].delete(key)
    end
  end

  module File
    # @ db,base,prefix
    def self.extended(obj)
      Msg.type?(obj,Var)
    end

    def ext_file(id)
      self['id']=id||Msg.cfg_err("ID")
      @base=self['type']+'_'+self['id']+'.json'
      @prefix=VarDir
      self
    end

    def load(tag=nil,pfx="VarFile")
      name=fname(tag)
      json_str=''
      open(name){|f|
        verbose(pfx,"Loading [#{@base}](#{f.size})",12)
        f.flock(::File::LOCK_SH) if File === f
        json_str=f.read
      }
      if json_str.empty?
        warning(pfx," -- json file (#{@base}) is empty")
      else
        super(json_str)
      end
      self
    rescue Errno::ENOENT
      if tag
        Msg.par_err("No such Tag","Tag=#{taglist}")
      else
        warning(pfx,"  -- no json file (#{@base})")
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
    @@vpfx="VarUrl"
    # @< base,prefix
    def self.extended(obj)
      Msg.type?(obj,File)
    end

    def ext_url(host)
      host||='localhost'
      @prefix="http://"+host
      verbose(@@vpfx,"Initialize")
      self
    end

    def load(tag=nil)
      super(tag,"VarUrl")
    rescue OpenURI::HTTPError
      warning("VarUrl","  -- no url file (#{fname})")
      self
    end
  end

  module Save
    # @< base,prefix
    def self.extended(obj)
      Msg.type?(obj,File)
    end

    def save(data=nil,tag=nil)
      name=fname(tag)
      open(name,'w'){|f|
        f.flock(::File::LOCK_EX)
        f << (data ? JSON.dump(data) : to_j)
        verbose("Var/Save","[#{@base}](#{f.size}) is Saved",12)
      }
      if tag
        # Making 'latest' tag link
        sname=fname('latest')
        ::File.unlink(sname) if ::File.symlink?(sname)
        ::File.symlink(name,sname)
        verbose("Var/save","Symboliclink to [#{sname}]")
      end
      self
    end
  end
end
