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
      self['id'] || Msg.cfg_err('No ID')
      @jsondir = vardir('json')
      @thread = Thread.current # For Thread safe
      self
    end

    def save(tag = nil)
      _write_json(to_j, tag)
    end

    def load(tag = nil)
      json_str = _read_json(tag)
      if json_str.empty?
        warning(" -- json file (#{_file_path_(tag)}) is empty at loading")
      end
      read(json_str) if _check_load(json_str)
      self
    end

    def save_key(keylist, tag = nil)
      tag ||= (_tag_list_.map{|i| i.to_i}.max + 1)
      Msg.msg("Status Saving for [#{tag}]")
      _write_json( pick(keylist), tag)
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

    def _check_load(json_str)
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
      json_str = ''
      open(fname) do|f|
        verbose { "Loading [#{fname}](#{f.size})" }
        f.flock(::File::LOCK_SH)
        json_str = f.read
      end
      json_str
    rescue Errno::ENOENT
      if tag
        Msg.par_err('No such Tag', "Tag=#{_tag_list_}")
      else
        warning("  -- no json file (#{fname})")
      end
    end
  end
end
