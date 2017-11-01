#!/usr/bin/ruby
module CIAX
  # Variable status data
  class Varx
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
        jstr = _read_json_(tag)
        verbose { "File Loading #{@cfile}" }
        if jstr.empty?
          verbose { " -- json file (#{@cfile}) is empty at loading" }
          return self
        end
        _check_load_(jstr) && jmerge(jstr)
        self
      end

      def save_key(keylist, tag = nil)
        tag ||= (_tag_list_.map(&:to_i).max + 1)
        # id is tag, this is Mark's request
        jstr = pick(
          keylist, time: self[:time], id: self[:id], ver: self[:ver]
        ).to_j
        msg("File Saving for [#{tag}]")
        _write_json(jstr, tag)
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
      def _check_load_(jstr)
        inc = j2h(jstr)[:ver]
        org = self[:ver]
        return true if inc == org
        warning("File version mismatch <#{inc}> for [#{org}]")
        false
      rescue CommError
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

      def _read_json_(tag = nil)
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

      def _write_json(jstr, tag = nil)
        _write_notice_(jstr)
        @cfile = _file_name(tag)
        open(@jsondir + @cfile, 'w') do |f|
          f.flock(::File::LOCK_EX)
          f << jstr
          verbose { "File [#{@cfile}](#{f.size}) is Saved" }
        end
        self
      end

      def _write_notice_(jstr)
        verbose(jstr.empty?) do
          " -- json data (#{jstr}) is empty at saving"
        end
        verbose(@thread != Thread.current) do
          'File Saving from Multiple Threads'
        end
      end
    end
  end
end
