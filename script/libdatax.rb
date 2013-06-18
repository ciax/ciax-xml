#!/usr/bin/ruby
require "libmsg"
require "libexenum"
require "libupdate"

module CIAX
  class Datax < ExHash
    include Msg
    attr_reader :upd_proc
    def initialize(type,init_struct={})
      self['type']=type
      self['time']=UnixTime.now
      @data=ExHash[init_struct]
      @upd_proc=[] # Proc Array
    end

    def to_j
      geth.to_j
    end

    def to_s
      geth.to_s
    end

    def upd # update after processing
      @upd_proc.each{|p| p.call(self)}
      self
    end

    def load(json_str=nil)
      str=json_str||gets(nil)||Msg.abort("No data in file(#{ARGV})")
      hash=seth(str)
      self['time']=UnixTime.parse(hash['time']||UnixTime.now)
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
      upd
    end

    def unset(key)
      @data.delete(key)
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

    private
    def geth
      hash=ExHash[self]
      hash['val']=@data
      hash
    end


    def seth(str)
      hash=JSON.load(str)
      @data=ExHash[hash.delete('val')||{}]
      replace hash
    end

    module File
      # @ db,base,prefix
      def self.extended(obj)
        Msg.type?(obj,Datax)
      end

      def ext_file(id)
        self['id']=id||Msg.cfg_err("ID")
        @base=self['type']+'_'+self['id']+'.json'
        @prefix=VarDir
        self
      end

      def load(tag=nil,pfx="DataFile")
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
      @@vpfx="DataUrl"
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
        super(tag,"DataUrl")
      rescue OpenURI::HTTPError
        warning("DataUrl","  -- no url file (#{fname})")
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
          verbose("Data/Save","[#{@base}](#{f.size}) is Saved",12)
        }
        if tag
          # Making 'latest' tag link
          sname=fname('latest')
          ::File.unlink(sname) if ::File.symlink?(sname)
          ::File.symlink(name,sname)
          verbose("Data/save","Symboliclink to [#{sname}]")
        end
        self
      end
    end
  end
end
