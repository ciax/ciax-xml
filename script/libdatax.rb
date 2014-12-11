#!/usr/bin/ruby
require "libvarx"

module CIAX
  # @data is hidden from access by '[]'.
  # @data is conveted to json file where @data will be appeared as self['data'].
  # @data never contains object which can't save with JSON
  class Datax < Varx
    def initialize(type,init_struct={},dataname='data')
      super(type)
      # Variable Data (Shown as 'data'(dataname) hash in JSON)
      @dataname=dataname
      @data=init_struct.dup.extend(Enumx)
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

    def size
      @data.size
    end

    def ext_file(tag=nil) # File I/O
      extend File
      ext_file(tag)
      self
    end

    def ext_http(host=nil,tag=nil) # Read only as a client
      extend Http
      ext_http(host,tag)
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
  end

  class DataH < Datax # @data is Hash
    # Update with strings (key=val,key=val,..)
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

    def get(key)
      @data[key]
    end

    def set(key,val)
      @data[key]=val
      self['time']=now_msec
      self
    ensure
      post_upd
    end

    def del(key)
      @data.delete(key)
      self['time']=now_msec
      self
    ensure
      post_upd
    end

    def keys
      @data.keys
    end

    def lastval
      get(keys.last)
    end
  end

  module Http
    require "open-uri"
    def ext_http(host,tag)
      @host=host||'localhost'
      verbose("Http","Initialize(#{@host})")
      self['id']||Msg.cfg_err("ID")
      @pre_upd_procs << proc{load(tag)}
      load
      self
    end

    def load(tag=nil)
      url=file_url(tag)
      json_str=''
      open(url){|f|
        verbose("Http","Loading [#{url}](#{f.size})")
        json_str=f.read
      }
      if json_str.empty?
        warning("Http"," -- json file (#{url}) is empty")
      else
        read(json_str)
      end
      self
    rescue OpenURI::HTTPError
      alert("Http","  -- no url file (#{url})")
    end

    private
    def file_url(tag=nil)
      "http://"+host+"/json/"+file_base(tag)+'.json'
    end
  end

  module File
    include Save
    def ext_file(tag=nil)
      ext_save(tag)
      load unless tag
      self
    end

    # Saving data of specified keys with tag
    def save_key(keylist,tag=nil)
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
        output=Hashx[self]
        output[@dataname]=hash
        write_json(output.to_j,tag)
      end
      self
    end

    def load(tag=nil)
      base=file_base(tag)
      fname=file_path(tag)
      json_str=''
      open(fname){|f|
        verbose("File","Loading [#{base}](#{f.size})")
        f.flock(::File::LOCK_SH)
        json_str=f.read
      }
      if json_str.empty?
        warning("File"," -- json file (#{base}) is empty")
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
        warning("File","  -- no json file (#{base})")
      end
    ensure
      post_upd
    end

    def tag_list
      Dir.glob(file_path('*')).map{|f|
        f.slice(/.+_(.+)\.json/,1)
      }.sort
    end
  end
end
