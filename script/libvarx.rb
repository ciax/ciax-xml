#!/usr/bin/ruby
require "libenumx"

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

    # update after processing (super should be end of method if inherited)
    def upd
      pre_upd
      verbose("Datax","UPD_PROC for [#{@type}:#{self['id']}]")
      self
    ensure
      post_upd
    end

    def set_db(db)
      @db=type?(db,Db)
      _setid(db['site_id']||db['id'])
      self['ver']=db['version'].to_i
      self
    end

    def ext_save # Save data at every after update
      extend Save
      ext_file
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
    def ext_save
      verbose("File","Initialize")
      @jpath=VarDir+"/json/"
      FileUtils.mkdir_p @jpath
      self['id']||Msg.cfg_err("ID")
      @post_upd_procs << proc{save}
      self
    end

    def save
      write_json(self)
    end

    private
    def write_json(data,tag=nil)
      verbose("File","Saving from Multiple Threads") unless @thread == Thread.current
      base=file_base(tag)+'.json'
      rname=@jpath+base
      open(rname,'w'){|f|
        f.flock(::File::LOCK_EX)
        f << JSON.dump(data)
        verbose("File","[#{base}](#{f.size}) is Saved")
      }
      if tag
        # Making 'latest' tag link
        sname=@jpath+file_base('latest')+'.json'
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
      loghead=VarDir+"/"+file_base
      verbose(@type.capitalize,"Initialize (#{id}/Ver.#{ver})")
      @queue=Queue.new
      @post_upd_procs << proc{
        @queue.push(JSON.dump(self))
      }
      ThreadLoop.new("Logging(#{@type}:#{ver})",11){
        logary=[]
        begin
          logary << @queue.pop
        end until @queue.empty?
        open(loghead+"_#{Time.now.year}.log",'a') {|f|
          logary.each{|str|
            f.puts str
            verbose(@type.capitalize,"Appended #{str.size} byte #{str}")
          }
        }
      }
    end
  end
end
