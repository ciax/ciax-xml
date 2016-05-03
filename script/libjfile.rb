#!/usr/bin/ruby
module CIAX
  # Add File I/O feature
  module JFile
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    # Set latest_link=true for making latest link at save
    def ext_local_file
      verbose { "Initiate File Status [#{_file_base}]" }
      self[:id] || cfg_err('No ID')
      @jsondir = vardir('json')
      @thread = Thread.current # For Thread safe
      self
    end

    def auto_save
      @cmt_procs << proc { save }
      self
    end

    def auto_load
      @upd_procs << proc { load }
      self
    end

    def save(tag = nil)
      _write_json(to_j, tag)
    end

    def load(tag = nil)
      json_str = _read_json(tag)
      verbose { "File Loading #{_file_name(tag)}" }
      if json_str.empty?
        verbose { " -- json file (#{_file_name(tag)}) is empty at loading" }
        return self
      end
      read(json_str) if _check_load(json_str)
      self
    end

    def save_key(keylist, tag = nil)
      tag ||= (_tag_list_.map(&:to_i).max + 1)
      json_str = pick(keylist, time: self[:time]).to_j
      msg("File Saving for [#{tag}]")
      _write_json(json_str, tag)
    end

    def mklink
      # Making 'latest' link
      save
      sname = @jsondir + "#{@type}_latest.json"
      ::File.unlink(sname) if ::File.exist?(sname)
      ::File.symlink(@jsondir + _file_name, sname)
      verbose { "File Symboliclink to [#{sname}]" }
      self
    end

    private

    # Version check, no read if different
    # (otherwise old version number remain as long as the file exists)
    def _check_load(json_str)
      return true if j2h(json_str)[:ver] == self[:ver]
      warning('File version mismatch')
      false
    end

    def _file_name(tag = nil)
      _file_base(tag) + '.json'
    end

    def _tag_list_
      Dir.glob(@jsondir + _file_name('*')).map do|f|
        f.slice(/.+_(.+)\.json/, 1)
      end.sort
    end

    def _write_json(json_str, tag = nil)
      verbose(@thread != Thread.current) { 'File Saving from Multiple Threads' }
      fname = _file_name(tag)
      open(@jsondir + fname, 'w') do|f|
        f.flock(::File::LOCK_EX)
        f << json_str
        verbose { "File [#{fname}](#{f.size}) is Saved" }
      end
      self
    end

    def _read_json(tag = nil)
      fname = _file_name(tag)
      open(@jsondir + fname) do|f|
        verbose { "Reading [#{fname}](#{f.size})" }
        f.flock(::File::LOCK_SH)
        f.read
      end || ''
    rescue Errno::ENOENT
      Msg.par_err('No such Tag', "Tag=#{_tag_list_}") if tag
      verbose { "  -- no json file (#{fname})" }
      ''
    end
  end
end
