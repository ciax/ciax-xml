#!/usr/bin/ruby
require "libmsg"
require "libdb"

module CIAX
  # @data is hidden from access by '[]'.
  # @data is conveted to json file where @data will be appeared as self['data'].
  class Datax < Hashx
    attr_reader :data,:upd_procs,:save_procs,:load_procs
    def initialize(type,init_struct={},dataname='data')
      self['type']=type
      self['time']=now_msec
      self['id']=nil
      self['ver']=nil
      @data=init_struct.dup.extend(Enumx)
      @dataname=dataname
      @thread=Thread.current # For Thread safe
      @ver_color=6
      @upd_procs=[] # Proc Array for Update Propagation to the upper Layers
      @save_procs=[] # Proc for Device Data Update (by Device response)
      @load_procs=[] # Proc for Device Data Update (by Device response)
    end

    def to_j
      _getdata.to_j
    end

    def to_s
      _getdata.to_s
    end

    def read(json_str=nil)
      super
      _setdata
      self
    end

    # update after processing (super should be end of method if inherited)
    def upd
      verbose("Datax","UPD_PROC for [#{self['type']}:#{self['id']}]")
      @upd_procs.each{|p| p.call(self)}
      self
    end

    # never inherit, just add proc to @save_procs
    def save
      verbose("Datax","SAVE_PROC for [#{self['type']}:#{self['id']}]")
      @save_procs.each{|p| p.call(self)}
      self
    end

    # never inherit, just add proc to @load_procs
    def load
      verbose("Datax","LOAD_PROC for [#{self['type']}:#{self['id']}]")
      @load_procs.each{|p| p.call(self)}
      self
    end

    def reg_procs(src)
      type?(src,Datax)
      src.upd_procs << proc{upd}
      src.load_procs << proc{load}
      src.save_procs << proc{save}
      self
    end

    # Update with str (key=val,key=val,..)
    def str_update(str)
      type?(str,String)
      str.split(',').each{|i|
        k,v=i.split('=')
        @data[k]=v
      }
      self['time']=now_msec
      upd
    end

    def unset(key)
      val=@data.delete(key)
      upd
      val
    end

    def set_db(db)
      @db=type?(db,Db)
      _setid(db['site_id']||db['id'])
      self['ver']=db['version'].to_i
      self
    end

    def ext_file
      extend File
      ext_file
      self
    end

    def ext_http(host=nil)
      extend Http
      ext_http(host)
      self
    end

    private
    def _getdata
      verbose("Datax","Convert @data to [:data]")
      hash=Hashx[self]
      hash[@dataname]=@data
      hash
    end

    def _setdata
      verbose("Datax","Convert [:data] to @data")
      @data=delete(@dataname).extend(Enumx)
      self['time']||=now_msec
      upd
    end

    def _setid(id)
      self['id']=id||Msg.cfg_err("ID")
      self
    end

    def file_name(tag=nil)
      @base=[self['type'],self['id'],tag].compact.join('_')+'.json'
      @prefix+@base
    end

    def tag_list
      Dir.glob(file_name('*')).map{|f|
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
      self['id']||Msg.cfg_err("ID")
      self
    end

    def load(tag=nil)
      name=file_name(tag)
      json_str=''
      open(name){|f|
        verbose("Http","Loading [#{@base}](#{f.size})",12)
        json_str=f.read
      }
      if json_str.empty?
        warning("Http"," -- json file (#{@base}) is empty")
      else
        read(json_str)
      end
      super()
      self
    rescue OpenURI::HTTPError
      warning("Http","  -- no url file (#{file_name})")
    end
  end

  module File
    def ext_file
      verbose("File","Initialize")
      @prefix=VarDir+"/json/"
      FileUtils.mkdir_p @prefix
      self['id']||Msg.cfg_err("ID")
      self
    end

    def save(tag=nil)
      write_json(_getdata,tag)
    end

    # Saving data of specified keys with tag
    def save_key(keylist,tag=nil)
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
        tag||=(tag_list.max{|a,b| a.to_i <=> b.to_i}.to_i+1)
        Msg.msg("Status Saving for [#{tag}]")
        output=Hash[self]
        output[@dataname]=hash
        write_json(output,tag)
      end
      self
    end

    def load(tag=nil)
      name=file_name(tag)
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
      super()
      self
    rescue Errno::ENOENT
      if tag
        Msg.par_err("No such Tag","Tag=#{tag_list}")
      else
        warning("File","  -- no json file (#{@base})")
      end
    end

    private
    def write_json(data,tag=nil)
      verbose("File","Saving from Multiple Threads") unless @thread == Thread.current
      name=file_name(tag)
      open(name,'w'){|f|
        f.flock(::File::LOCK_EX)
        f << JSON.dump(data)
        verbose("File","[#{@base}](#{f.size}) is Saved",12)
      }
      if tag
        # Making 'latest' tag link
        sname=file_name('latest')
        ::File.unlink(sname) if ::File.symlink?(sname)
        ::File.symlink(name,sname)
        verbose("File","Symboliclink to [#{sname}]")
      end
      @save_procs.each{|p| p.call(self)}
      self
    end
  end
end
