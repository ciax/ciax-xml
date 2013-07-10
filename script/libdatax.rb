#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libupdate"

module CIAX
  class Datax < ExHash
    def initialize(type,init_struct={})
      self['type']=type
      self['time']=UnixTime.now
      @data=ExHash[init_struct]
      @ver_color=6
    end

    def to_j
      geth.to_j
    end

    def to_s
      geth.to_s
    end

    def read(json_str=nil)
      super
      seth
    end

    # Update with str (key=val,key=val,..)
    def str_update(str)
      type?(str,String)
      str.split(',').each{|i|
        k,v=i.split('=')
        @data[k]=v
      }
      self['time']=UnixTime.now
      self
    end

    def unset(key)
      @data.delete(key)
    end

    def ext_file(id)
      extend File
      ext_fname(id)
      self
    end

    def ext_http(id,host=nil)
      extend Http
      ext_http(id,host)
      self
    end

    private
    def geth
      hash=ExHash[self]
      hash['val']=@data
      hash
    end

    def seth
      @data=ExHash[delete('val')||{}]
      self['time']=UnixTime.parse(self['time']||UnixTime.now)
      self
    end
  end

  module Fname
    attr_reader :upd_proc
    def ext_fname(id)
      self['id']=id||Msg.cfg_err("ID")
      @base=self['type']+'_'+self['id']+'.json'
      @prefix=VarDir
      @upd_proc=[] # Proc Array for Update Propagation to the upper Layers
      self
    end

    def upd # update after processing
      @upd_proc.each{|p| p.call(self)}
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

  module Http
    require "open-uri"
    include Fname
    def ext_http(id,host)
      ext_fname(id)
      host||='localhost'
      @prefix="http://"+host
      verbose("Http","Initialize")
      self
    end

    def load(tag=nil)
      name=fname(tag)
      json_str=''
      open(name){|f|
        verbose("Http","Loading [#{@base}](#{f.size})",12)
        json_str=f.read
      }
      warning(pfx," -- json file (#{@base}) is empty") if json_str.empty?
      j2h(json_str)
    rescue OpenURI::HTTPError
      warning("Http","  -- no url file (#{fname})")
    end
  end

  module File
    include Fname
    def save(tag=nil)
      writej(geth,tag)
    end

    # Saving data of specified keys with tag
    def savekey(keylist,tag=nil)
      Msg.com_err("No File") unless @base
      hash={}
      keylist.each{|k|
        if @data.key?(k)
          hash[k]=get(k)
        else
          warning("File","No such Key [#{k}]")
        end
      }
      if hash.empty?
        Msg.par_err("No Keys")
      else
        tag||=(taglist.max{|a,b| a.to_i <=> b.to_i}.to_i+1)
        Msg.msg("Status Saving for [#{tag}]")
        writej({'val'=>hash},tag)
      end
      self
    end

    def load(tag=nil)
      name=fname(tag)
      json_str=''
      open(name){|f|
        verbose("File","Loading [#{@base}](#{f.size})",12)
        f.flock(::File::LOCK_SH)
        json_str=f.read
      }
      warning("File"," -- json file (#{@base}) is empty") if json_str.empty?
      j2h(json_str)
    rescue Errno::ENOENT
      if tag
        Msg.par_err("No such Tag","Tag=#{taglist}")
      else
        warning("File","  -- no json file (#{@base})")
      end
    end

    private
    def writej(data,tag=nil)
      name=fname(tag)
      open(name,'w'){|f|
        f.flock(::File::LOCK_EX)
        f << JSON.dump(data)
        verbose("File","[#{@base}](#{f.size}) is Saved",12)
      }
      if tag
        # Making 'latest' tag link
        sname=fname('latest')
        ::File.unlink(sname) if ::File.symlink?(sname)
        ::File.symlink(name,sname)
        verbose("File","Symboliclink to [#{sname}]")
      end
      self
    end
  end
end
