#!/usr/bin/ruby
require 'libsqlog'
module CIAX
  module Save
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    # Set latest_link=true for making latest link at save
    def ext_save
      verbose { "Save Initialize [#{file_base}]" }
      self['id'] || Msg.cfg_err('No ID')
      @jsondir = vardir('json')
      @post_upd_procs << proc do
        verbose { 'Propagate upd -> Save#save' }
        save
      end
      self
    end

    def mklink
      # Making 'latest' link
      save
      sname = @jsondir + "#{@type}_latest.json"
      ::File.unlink(sname) if ::File.exist?(sname)
      ::File.symlink(file_path, sname)
      verbose { "Symboliclink to [#{sname}]" }
      self
    end

    def save
      write_json(to_j)
    end

    def ext_sqlog
      # Logging if version number exists
      SqLog::Save.new(self['id'], @type).add_table(self)
      self
    end

    private
    def file_path(tag = nil)
      @jsondir + file_base(tag) + '.json'
    end

    def write_json(json_str, tag = nil)
      verbose(@thread != Thread.current) { 'Saving from Multiple Threads' }
      rname = file_path(tag)
      open(rname, 'w') do|f|
        f.flock(::File::LOCK_EX)
        f << json_str
        verbose { "[#{rname}](#{f.size}) is Saved" }
      end
      self
    end
  end

  module Log
    def ext_log # logging with flatten
      id = self['id']
      ver = self['ver']
      verbose { "Log Initialize [#{id}/Ver.#{ver}]" }
      @queue = Queue.new
      @post_upd_procs << proc do
        verbose { 'Propagate upd -> Log#queue' }
        @queue.push(to_j)
      end
      logfile = vardir('log') + file_base + "_#{Time.now.year}.log"
      ThreadLoop.new("Logging(#{@type}:#{id})", 11) do
        logary = []
        loop do
          logary << @queue.pop
          break if @queue.empty?
        end
        open(logfile, 'a') do|f|
          logary.each do|str|
            f.puts str
            verbose { "Appended #{str.size} byte" }
          end
        end
      end
      self
    end
  end
end
