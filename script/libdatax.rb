#!/usr/bin/ruby
require "libmsg"
require "libenumx"

module CIAX
  class Datax < Hashx
    attr_reader :data,:upd_procs,:save_procs
    # @data is hidden from access by '[]'
    def initialize(type,init_struct={},dataname='data')
      self['type']=type
      self['time']=UnixTime.now
      self['id']=nil
      self['ver']=nil
      @data=init_struct.dup.extend(Enumx)
      @dataname=dataname
      @ver_color=6
      @upd_procs=[] # Proc Array for Update Propagation to the upper Layers
      @save_procs=[] # Proc for Device Data Update (by Device response)
    end

    def to_j
      _getdata.to_j
    end

    def to_s
      _getdata.to_s
    end

    def upd # update after processing
      @upd_procs.each{|p| p.call(self)}
      self
    end

    def read(json_str=nil)
      super
      _setdata
      self
    end

    def save
      @save_procs.each{|p| p.call(self)}
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
      @upd_procs.each{|p| p.call(self)}
      self
    end

    def unset(key)
      val=@data.delete(key)
      @upd_procs.each{|p| p.call(self)}
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
      hash=Hashx[self]
      hash[@dataname]=@data
      hash
    end

    def _setdata
      @data=delete(@dataname).extend(Enumx)
      self['time']=UnixTime.parse(self['time']||UnixTime.now)
      @upd_procs.each{|p| p.call(self)}
      self
    end

    def _setid(id)
      self['id']=id||Msg.cfg_err("ID")
      self
    end

    def fname(tag=nil)
      @base=[self['type'],self['id'],tag].compact.join('_')+'.json'
      @prefix+@base
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
      @prefix="http://"+host+"/json/"
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
      if json_str.empty?
        warning(pfx," -- json file (#{@base}) is empty")
      else
        read(json_str)
      end
    rescue OpenURI::HTTPError
      warning("Http","  -- no url file (#{fname})")
    end
  end

  module File
    def ext_file
      verbose("File","Initialize")
      @prefix=VarDir+"/json/"
      FileUtils.mkdir_p @prefix
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
        writej({@dataname => hash},tag)
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
      if json_str.empty?
        warning("File"," -- json file (#{@base}) is empty")
      else
        read(json_str)
      end
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
      @save_procs.each{|p| p.call(self)}
      self
    end
  end
end
