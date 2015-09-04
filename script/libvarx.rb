#!/usr/bin/ruby
require "libupd"
require "libdb"

module CIAX
  # Variable Status Data with Saving, Logging feature
  # Need Header(id,ver) data
  class Varx < Upd
    attr_reader :type
    def initialize(type,id=nil,ver=nil,host=nil)
      super()
      @type=type
      # Headers
      self['time']=now_msec
      self['id']=id
      self['ver']=ver
      self['host']=host||`hostname`.strip
      # Setting (Not shown in JSON)
      @thread=Thread.current # For Thread safe
    end


    def set_db(db)
      @db=type?(db,Dbi)
      _setid(db['site_id']||db['id'])
      self['ver']=db['version'].to_i
      self
    end

    def ext_save # Save data at every after update
      extend Save
      ext_save
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
  end

  module Save
    # Set latest_link=true for making latest link at save
    def ext_save
      verbose("Save Initialize [#{file_base}]")
      self['id']||Msg.cfg_err("No ID")
      @jsondir=vardir('json')
      @post_upd_procs << proc{
        verbose("Propagate upd -> Save#save")
        save
      }
      self
    end

    def mklink
      # Making 'latest' link
      sname=@jsondir+"#{@type}_latest.json"
      ::File.unlink(sname) if ::File.exist?(sname)
      ::File.symlink(file_path,sname)
      verbose("Symboliclink to [#{sname}]")
      self
    end

    def save
      write_json(to_j)
    end

    private
    def file_path(tag=nil)
      @jsondir+file_base(tag)+'.json'
    end

    def write_json(json_str,tag=nil)
      verbose("Saving from Multiple Threads") unless @thread == Thread.current
      rname=file_path(tag)
      open(rname,'w'){|f|
        f.flock(::File::LOCK_EX)
        f << json_str
        verbose("[#{rname}](#{f.size}) is Saved")
      }
      self
    end
  end

  module Log
    def ext_log # logging with flatten
      id=self['id']
      ver=self['ver']
      verbose("Log Initialize [#{id}/Ver.#{ver}]")
      @queue=Queue.new
      @post_upd_procs << proc{
        verbose("Propagate upd -> Log#queue")
        @queue.push(to_j)
      }
      logfile=vardir("log")+file_base+"_#{Time.now.year}.log"
      ThreadLoop.new("Logging(#{@type}:#{id})",11){
        logary=[]
        begin
          logary << @queue.pop
        end until @queue.empty?
        open(logfile,'a') {|f|
          logary.each{|str|
            f.puts str
            verbose("Appended #{str.size} byte",str)
          }
        }
      }
    end
  end
end
