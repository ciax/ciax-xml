#!/usr/bin/ruby
require "libenumx"
require "libdb"

module CIAX
  class Varx < Hashx
    attr_reader :type,:pre_upd_procs,:post_upd_procs
    def initialize(type,id=nil,ver=nil,host=nil)
      @type=type
      # Headers
      self['time']=now_msec
      self['id']=id
      self['ver']=ver
      self['host']=host||`hostname`.strip
      # Setting (Not shown in JSON)
      @thread=Thread.current # For Thread safe
      @cls_color=2
      @pfx_color=6
      # Updater
      @pre_upd_procs=[] # Proc Array for Pre-Process of Update Propagation to the upper Layers
      @post_upd_procs=[] # Proc Array for Post-Process of Update Propagation to the upper Layers
    end

    # update after processing (never iniherit, use convert() instead)
    def upd
      pre_upd # Loading file at client
      verbose("Varx","UPD_PROC for [#{@type}:#{self['id']}]")
      convert # Data conversion
      self
    ensure
      post_upd # Save & Update super layer
    end

    def set_db(db)
      @db=type?(db,Db)
      _setid(db['site_id']||db['id'])
      self['ver']=db['version'].to_i
      self
    end

    def ext_save(tag=nil) # Save data at every after update
      extend Save
      ext_save(tag)
      self
    end

    def ext_log # Write only for server
      extend Log
      ext_log
      self
    end

    private
    def _setid(id)
      self['id']=id||Msg.cfg_err("ID")
      self
    end

    def file_base(tag=nil)
      [@type,self['id'],tag].compact.join('_')
    end

    # Inherit convert() for upd function
    def convert
      self
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

  module Save
    def ext_save(tag=nil)
      verbose("File","Initialize")
      FileUtils.mkdir_p(VarDir+"/json/")
      self['id']||Msg.cfg_err("ID")
      @post_upd_procs << proc{save(tag)}
      self
    end

    def save(tag=nil)
      write_json(to_j,tag)
    end

    private
    def file_path(tag=nil)
      VarDir+"/json/"+file_base(tag)+'.json'
    end

    def write_json(json_str,tag=nil)
      verbose("File","Saving from Multiple Threads") unless @thread == Thread.current
      rname=file_path(tag)
      open(rname,'w'){|f|
        f.flock(::File::LOCK_EX)
        f << json_str
        verbose("File","[#{rname}](#{f.size}) is Saved")
      }
      if tag
        # Making 'latest' tag link
        sname=file_path('latest')
        ::File.unlink(sname) if ::File.symlink?(sname)
        ::File.symlink(rname,sname)
        verbose("File","Symboliclink to [#{sname}]")
      end
      self
    end
  end

  module Log
    def ext_log # logging with flatten
      FileUtils.mkdir_p VarDir
      id=self['id']
      ver=self['ver']
      verbose(@type.capitalize,"Initialize (#{id}/Ver.#{ver})")
      @queue=Queue.new
      @post_upd_procs << proc{
        @queue.push(to_j)
      }
      ThreadLoop.new("Logging(#{@type}:#{id})",11){
        logary=[]
        begin
          logary << @queue.pop
        end until @queue.empty?
        open(logpath,'a') {|f|
          logary.each{|str|
            f.puts str
            verbose(@type.capitalize,"Appended #{str.size} byte #{str}")
          }
        }
      }
    end

    private
    def logpath(tag=nil)
      VarDir+"/"+file_base(tag)+"_#{Time.now.year}.log"
    end
  end
end
