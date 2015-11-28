#!/usr/bin/ruby
require 'libjslog'
module CIAX
  # Add File I/O feature
  module JFile
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    # Set latest_link=true for making latest link at save
    def ext_file
      verbose { "File IO Initialize [#{_file_base}]" }
      self[:id] || Msg.cfg_err('No ID')
      @jsondir = vardir('json')
      @thread = Thread.current # For Thread safe
      load
      self
    end

    def auto_save
      @post_upd_procs << proc { save }
      upd
      self
    end

    def auto_load
      @pre_upd_procs << proc { load }
      upd
      self
    end

    def save(tag = nil)
      _write_json(to_j, tag)
    end

    def read
      super(_read_json)
    end

    def load(tag = nil)
      json_str = _read_json(tag)
      verbose { "Loading #{_file_path_(tag)}" }
      if json_str.empty?
        warning(" -- json file (#{_file_path_(tag)}) is empty at loading")
        return self
      end
      super(json_str) if _check_load(json_str)
      self
    end

    def save_key(keylist, tag = nil)
      tag ||= (_tag_list_.map(&:to_i).max + 1)
      Msg.msg("Status Saving for [#{tag}]")
      _write_json(pick(keylist).to_j, tag)
    end

    def mklink
      # Making 'latest' link
      save
      sname = @jsondir + "#{@type}_latest.json"
      ::File.unlink(sname) if ::File.exist?(sname)
      ::File.symlink(_file_path_, sname)
      verbose { "Symboliclink to [#{sname}]" }
      self
    end

    private

    def _check_load(_json_str)
      true
    end

    def _file_path_(tag = nil)
      @jsondir + _file_base(tag) + '.json'
    end

    def _tag_list_
      Dir.glob(_file_path_('*')).map do|f|
        f.slice(/.+_(.+)\.json/, 1)
      end.sort
    end

    def _write_json(json_str, tag = nil)
      verbose(@thread != Thread.current) { 'Saving from Multiple Threads' }
      fname = _file_path_(tag)
      open(fname, 'w') do|f|
        f.flock(::File::LOCK_EX)
        f << json_str
        verbose { "[#{fname}](#{f.size}) is Saved" }
      end
      self
    end

    def _read_json(tag = nil)
      fname = _file_path_(tag)
      open(fname) do|f|
        verbose { "Reading [#{fname}](#{f.size})" }
        f.flock(::File::LOCK_SH)
        f.read
      end || ''
    rescue Errno::ENOENT
      Msg.par_err('No such Tag', "Tag=#{_tag_list_}") if tag
      warning("  -- no json file (#{fname})")
      ''
    end
  end
end
