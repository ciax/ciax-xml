#!/usr/bin/ruby
require 'libvarx'
require 'libsqlog'
module CIAX
  # Add Data saving feature with JSON
  module JSave
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    # Set latest_link=true for making latest link at save
    def ext_save
      verbose { "Save Initialize [#{_file_base}]" }
      self['id'] || Msg.cfg_err('No ID')
      @post_upd_procs << proc { save }
      self
    end

    def mklink
      # Making 'latest' link
      save
      sname = @jsondir + "#{@type}_latest.json"
      ::File.unlink(sname) if ::File.exist?(sname)
      ::File.symlink(_file_path, sname)
      verbose { "Symboliclink to [#{sname}]" }
      self
    end

    def save
      _write_json(to_j)
    end

    def ext_sqlog
      # Logging if version number exists
      SqLog::Save.new(self['id'], @type).add_table(self)
      self
    end

    private

    def _write_json(json_str, tag = nil)
      verbose(@thread != Thread.current) { 'Saving from Multiple Threads' }
      rname = _file_path(tag)
      open(rname, 'w') do|f|
        f.flock(::File::LOCK_EX)
        f << json_str
        verbose { "[#{rname}](#{f.size}) is Saved" }
      end
      self
    end
  end

  # Add extend method to Varx
  class Varx
    def ext_save
      extend(JSave).ext_save
    end
  end
end
