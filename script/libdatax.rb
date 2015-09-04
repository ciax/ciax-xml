#!/usr/bin/ruby
require "libvarx"

module CIAX
  # Header and Data Container(Hash or Array) with Loading feature
  class Datax < Varx
    # @data is hidden from access by '[]'.
    # @data is conveted to json file where @data will be appeared as self['data'].
    # @data never contains object which can't save with JSON
    def initialize(type,init_struct={},data_name='data')
      super(type)
      # Variable Data (Shown as 'data'(data_name) hash in JSON)
      @data_name=data_name
      @data=init_struct.dup.extend(Enumx)
    end

    def to_j
      _getdata.to_j
    end

    def to_r
      _getdata.to_r
    end

    def read(json_str=nil)
      super
      _setdata
      self
    end

    def size
      @data.size
    end

    def get(id)
      @data[id]
    end

    def num(n)
      get(@data.keys.sort[n])
    end

    def ext_file # File I/O
      extend File
      ext_file
      self
    end

    def ext_http(host=nil) # Read only as a client
      extend Http
      ext_http(host)
      self
    end

    private
    def _getdata
      verbose("Convert @data to [:data]")
      hash=Hashx.new(self)
      hash[@data_name]=@data
      hash
    end

    def _setdata
      verbose("Convert [:data] to @data")
      @data=delete(@data_name).extend(Enumx)
      self['time']||=now_msec
      self
    end
  end

  # Data container is Hash
  class DataH < Datax
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

    def put(key,val) # super should be placed at the end of method
      @data[key]=val
      self['time']=now_msec
      val
    ensure
      post_upd
    end

    # Replace value
    def rep(key,val)
      Msg.par_err("No such Key [#{key}]") unless @data.key?(key)
      (@data[key]||='').replace(val)
      self['time']=now_msec
      val
    ensure
      post_upd
    end

    def del(key) # super should be placed at the end of method
      @data.delete(key)
      self['time']=now_msec
      self
    ensure
      post_upd
    end

    def keys
      @data.keys
    end

    def key?(key)
      @data.key?(key)
    end

    def values
      @data.values
    end

    def lastval
      get(keys.last)
    end
  end

  module Http
    require "open-uri"
    def ext_http(host)
      @host=host||'localhost'
      verbose("Initialize(#{@host})")
      self['id']||Msg.cfg_err("ID")
      @pre_upd_procs << proc{load}
      load
      self
    end

    def load(tag=nil)
      url=file_url(tag)
      json_str=''
      open(url){|f|
        verbose("Loading [#{url}](#{f.size})")
        json_str=f.read
      }
      if json_str.empty?
        warning(" -- json file (#{url}) is empty")
      else
        read(json_str)
      end
      self
    rescue OpenURI::HTTPError
      alert("  -- no url file (#{url})")
    end

    private
    def file_url(tag=nil)
      "http://"+@host+"/json/"+file_base(tag)+'.json'
    end
  end

  module File
    include Save
    def ext_file
      ext_save
      load
      self
    end

    # Saving data of specified keys with tag
    def save_key(keylist,tag=nil)
      hash={}
      keylist.each{|k|
        if @data.key?(k)
          hash[k]=get(k)
        else
          warning("No such Key [#{k}]")
        end
      }
      if hash.empty?
        Msg.par_err("No Keys")
      else
        tag||=(tag_list.max{|a,b| a.to_i <=> b.to_i}.to_i+1)
        Msg.msg("Status Saving for [#{tag}]")
        output=Hashx.new(self)
        output[@data_name]=hash
        write_json(output.to_j,tag)
      end
      self
    end

    def load(tag=nil)
      base=file_base(tag)
      fname=file_path(tag)
      json_str=''
      open(fname){|f|
        verbose("Loading [#{base}](#{f.size})")
        f.flock(::File::LOCK_SH)
        json_str=f.read
      }
      if json_str.empty?
        warning(" -- json file (#{base}) is empty")
      else
        data=j2h(json_str)
        verbose("Version compare [#{data['ver']}] vs. <#{self['ver']}>")
        if data['ver'] == self['ver']
          @data.deep_update(data[@data_name])
        else
          alert("Version mismatch [#{data['ver']}] should be <#{self['ver']}>")
        end
      end
      self
    rescue Errno::ENOENT
      if tag
        Msg.par_err("No such Tag","Tag=#{tag_list}")
      else
        warning("  -- no json file (#{base})")
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
