#!/usr/bin/ruby
module CIAX
  # Add File I/O feature
  module JFile
    def self.extended(obj)
      Msg.type?(obj, Varx)
    end

    # Set latest_link=true for making latest link at save
    def ext_local_file(dir = nil)
      verbose { "Initiate File Status [#{_file_base}]" }
      self[:id] || cfg_err('No ID')
      @thread = Thread.current # For Thread safe
      @jsondir = vardir(dir || 'json')
      @cfile = _file_base # Current file name
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
      verbose { "File Loading #{@cfile}" }
      if json_str.empty?
        verbose { " -- json file (#{@cfile}) is empty at loading" }
        return self
      end
      _check_load(json_str)
      jmerge(json_str)
      self
    end

    def save_key(keylist, tag = nil)
      tag ||= (_tag_list_.map(&:to_i).max + 1)
      # id is tag, this is Mark's request
      json_str = pick(keylist, time: self[:time], id: self[:id]).to_j
      msg("File Saving for [#{tag}]")
      _write_json(json_str, tag)
    end

    def mklink(tag = 'latest')
      # Making 'latest' link
      save
      sname = vardir('json') + "#{@type}_#{tag}.json"
      ::File.unlink(sname) if ::File.exist?(sname)
      ::File.symlink(@jsondir + _file_name, sname)
      verbose { "File Symboliclink to [#{sname}]" }
      self
    end

    private

    # Version check, no read if different
    # (otherwise old version number remain as long as the file exists)
    def _check_load(json_str)
      inc = j2h(json_str)[:ver]
      org = self[:ver]
      warning("File version mismatch <#{inc}> for [#{org}]") if inc != org
      false
    rescue UserError
      relay(@cfile.to_s)
    end

    def _file_name(tag = nil)
      _file_base(tag) + '.json'
    end

    def _tag_list_
      Dir.glob(@jsondir + _file_name('*')).map do |f|
        f.slice(/.+_(.+)\.json/, 1)
      end.sort
    end

    def _write_json(json_str, tag = nil)
      verbose(@thread != Thread.current) { 'File Saving from Multiple Threads' }
      @cfile = _file_name(tag)
      open(@jsondir + @cfile, 'w') do |f|
        f.flock(::File::LOCK_EX)
        f << json_str
        verbose { "File [#{@cfile}](#{f.size}) is Saved" }
      end
      self
    end

    def _read_json(tag = nil)
      @cfile = _file_name(tag)
      open(@jsondir + @cfile) do |f|
        verbose { "Reading [#{@cfile}](#{f.size})" }
        f.flock(::File::LOCK_SH)
        f.read
      end || ''
    rescue Errno::ENOENT
      Msg.par_err('No such Tag', "Tag=#{_tag_list_}") if tag
      verbose { "  -- no json file (#{@cfile})" }
      ''
    end
  end
end
