#!/usr/bin/ruby
require "libdb"

module CIAX
  # @data is hidden from access by '[]'.
  # @data is conveted to json file where @data will be appeared as self['data'].
  # @data never contains object which can't save with JSON
  class Datax < Hashx
    attr_reader :type,:data,:pre_upd_procs,:post_upd_procs
    def initialize(type,init_struct={},dataname='data')
      @type=type
      self['time']=now_msec
      self['id']=nil
      self['ver']=nil
      self['host']=`hostname`.strip
      @data=init_struct.dup.extend(Enumx)
      @dataname=dataname
      @thread=Thread.current # For Thread safe
      @cls_color=2
      @pfx_color=6
      @pre_upd_procs=[] # Proc Array for Pre-Process of Update Propagation to the upper Layers
      @post_upd_procs=[] # Proc Array for Post-Process of Update Propagation to the upper Layers
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
      pre_upd
      verbose("Datax","UPD_PROC for [#{@type}:#{self['id']}]")
      self
    ensure
      post_upd
    end

    # Update with str (key=val,key=val,..)
    def str_update(str)
      type?(str,String)
      str.split(',').each{|i|
        k,v=i.split('=')
        @data[k]=v
      }
      self['time']=now_msec
    ensure
      post_upd
    end

    def set(key,val)
      @data[key]=val
      self['time']=now_msec
      self
    ensure
      post_upd
    end

    def unset(key)
      @data.delete(key)
    ensure
      post_upd
    end

    def set_db(db)
      @db=type?(db,Db)
      _setid(db['site_id']||db['id'])
      self['ver']=db['version'].to_i
      self
    end

    def ext_file(tag=nil)
      extend File
      ext_file(tag)
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
      self
    end

    def _setid(id)
      self['id']=id||Msg.cfg_err("ID")
      self
    end

    def file_name(tag=nil)
      @base=[@type,self['id'],tag].compact.join('_')+'.json'
      @prefix+@base
    end

    def tag_list
      Dir.glob(file_name('*')).map{|f|
        f.slice(/.+_(.+)\.json/,1)
      }.sort
    end

    def pre_upd
      @pre_upd_procs.each{|p| p.call(self)}
      self
    end

    def post_upd
      @post_upd_procs.each{|p| p.call(self)}
      self
    end
  end

  module Http
    require "open-uri"
    def ext_http(host)
      host||='localhost'
      verbose("Http","Initialize(#{host})")
      @prefix="http://"+host+"/json/"
      self['id']||Msg.cfg_err("ID")
      @pre_upd_procs << proc{load}
      load
      self
    end

    def load(tag=nil)
      name=file_name(tag)
      json_str=''
      open(name){|f|
        verbose("Http","Loading [#{@base}](#{f.size})")
        json_str=f.read
      }
      if json_str.empty?
        warning("Http"," -- json file (#{@base}) is empty")
      else
        read(json_str)
      end
      self
    rescue OpenURI::HTTPError
      alert("Http","  -- no url file (#{file_name})")
    end
  end

  module File
    def ext_file(tag=nil)
      verbose("File","Initialize")
      @prefix=VarDir+"/json/"
      FileUtils.mkdir_p @prefix
      self['id']||Msg.cfg_err("ID")
      @post_upd_procs << proc{save(tag)}
      load unless tag
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
        verbose("File","Loading [#{@base}](#{f.size})")
        f.flock(::File::LOCK_SH)
        json_str=f.read
      }
      if json_str.empty?
        warning("File"," -- json file (#{@base}) is empty")
      else
        data=j2h(json_str)
        verbose("File","Version compare [#{data['ver']}] vs. <#{self['ver']}>")
        if data['ver'] == self['ver']
          @data.deep_update(data[@dataname])
        else
          alert("File","Version mismatch [#{data['ver']}] should be <#{self['ver']}>")
        end
      end
      self
    rescue Errno::ENOENT
      if tag
        Msg.par_err("No such Tag","Tag=#{tag_list}")
      else
        warning("File","  -- no json file (#{@base})")
      end
    ensure
      post_upd
    end

    private
    def write_json(data,tag=nil)
      verbose("File","Saving from Multiple Threads") unless @thread == Thread.current
      name=file_name(tag)
      open(name,'w'){|f|
        f.flock(::File::LOCK_EX)
        f << JSON.dump(data)
        verbose("File","[#{@base}](#{f.size}) is Saved")
      }
      if tag
        # Making 'latest' tag link
        sname=file_name('latest')
        ::File.unlink(sname) if ::File.symlink?(sname)
        ::File.symlink(name,sname)
        verbose("File","Symboliclink to [#{sname}]")
      end
      self
    end
  end
end
