#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libupdate"

module CIAX
  class Datax < ExHash
    attr_reader :data,:upd_proc
    def initialize(type,init_struct={})
      self['type']=type
      self['time']=UnixTime.now
      @data=ExHash[init_struct]
      @ver_color=6
      @upd_proc=[] # Proc Array for Update Propagation to the upper Layers
    end

    def to_j
      _getdata.to_j
    end

    def to_s
      _getdata.to_s
    end

    def upd # update after processing
      @upd_proc.each{|p| p.call(self)}
      self
    end

    def read(json_str=nil)
      super
      _setdata
      self
    end

    # Update with str (key=val,key=val,..)
    def str_update(str)
      type?(str,String)
      str.split(',').each{|i|
        k,v=i.split('=')
        @data[k]=v
      }
      self['time']=UnixTime.now
      @upd_proc.each{|p| p.call(self)}
      self
    end

    def unset(key)
      val=@data.delete(key)
      @upd_proc.each{|p| p.call(self)}
      val
    end

    def ext_file(id)
      extend File
      _setid(id)
      ext_file
      self
    end

    def ext_http(id,host=nil)
      extend Http
      _setid(id)
      ext_http(host)
      self
    end

    private
    def _getdata
      hash=ExHash[self]
      hash['val']=@data
      hash
    end

    def _setdata
      @data=ExHash[delete('val')||{}]
      self['time']=UnixTime.parse(self['time']||UnixTime.now)
      @upd_proc.each{|p| p.call(self)}
      self
    end

    def _setid(id)
      self['id']=id||Msg.cfg_err("ID")
      @base=self['type']+'_'+self['id']+'.json'
      @prefix=VarDir
      self
    end

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
    def ext_http(host)
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
      read(json_str)
    rescue OpenURI::HTTPError
      warning("Http","  -- no url file (#{fname})")
    end
  end

  module File
    attr_reader :save_proc
    def ext_file
      @save_proc=[]
      verbose("File","Initialize")
      self
    end

    def save(tag=nil)
      writej(_getdata,tag)
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
      read(json_str)
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
      @save_proc.each{|p| p.call(self)}
      self
    end
  end
end
