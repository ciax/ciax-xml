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
        verbose { "Initiate File Status [#{base_name}]" }
        self[:id] || cfg_err('No ID')
        @thread = Thread.current # For Thread safe
        @jsondir = vardir(dir || 'json')
        @cfile = base_name # Current file name
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
        __write_json(to_j, tag)
      end

      def load(tag = nil)
        jstr = ___read_json(tag)
        verbose { "File Loading #{@cfile}" }
        if jstr.empty?
          verbose { " -- json file (#{@cfile}) is empty at loading" }
          return self
        end
        ___check_load(jstr) && jmerge(jstr)
        self
      end

      def save_key(keylist, tag = nil)
        tag ||= (__tag_list.map(&:to_i).max + 1)
        # id is tag, this is Mark's request
        jstr = pick(
          keylist, time: self[:time], id: self[:id], ver: self[:ver]
        ).to_j
        msg("File Saving for [#{tag}]")
        __write_json(jstr, tag)
      end

      def mklink(tag = 'latest')
        # Making 'latest' link
        save
        sname = vardir('json') + "#{@type}_#{tag}.json"
        ::File.unlink(sname) if ::File.exist?(sname)
        ::File.symlink(@jsondir + __file_name, sname)
        verbose { "File Symboliclink to [#{sname}]" }
        self
      end

      private

      # Version check, no read if different
      # (otherwise old version number remain as long as the file exists)
      def ___check_load(jstr)
        inc = j2h(jstr)[:ver]
        org = self[:ver]
        return true if inc == org
        warning("File version mismatch <#{inc}> for [#{org}]")
        false
      rescue CommError
        relay(@cfile.to_s)
      end

      def __file_name(tag = nil)
        base_name(tag) + '.json'
      end

      def __tag_list
        Dir.glob(@jsondir + __file_name('*')).map do |f|
          f.slice(/.+_(.+)\.json/, 1)
        end.sort
      end

      def ___read_json(tag = nil)
        @cfile = __file_name(tag)
        open(@jsondir + @cfile) do |f|
          verbose { "Reading [#{@cfile}](#{f.size})" }
          f.flock(::File::LOCK_SH)
          f.read
        end || ''
      rescue Errno::ENOENT
        Msg.par_err('No such Tag', "Tag=#{__tag_list}") if tag
        verbose { "  -- no json file (#{@cfile})" }
        ''
      end

      def __write_json(jstr, tag = nil)
        ___write_notice(jstr)
        @cfile = __file_name(tag)
        open(@jsondir + @cfile, 'w') do |f|
          f.flock(::File::LOCK_EX)
          f << jstr
          verbose { "File [#{@cfile}](#{f.size}) is Saved" }
        end
        self
      end

      def ___write_notice(jstr)
        verbose(jstr.empty?) do
          " -- json data (#{jstr}) is empty at saving"
        end
        verbose(@thread != Thread.current) do
          'File Saving from Multiple Threads'
        end
      end

      module_function

      # Using for RecArc, RecList
      def jload(fname)
        j2h(loadfile(fname))
      rescue InvalidData
        Hashx.new
      end

      def loadfile(fname)
        open(fname) do |f|
          f.flock(::File::LOCK_SH)
          f.read
        end
      rescue Errno::ENOENT
        verbose { "  -- no json file (#{fname})" }
      end
    end
  end
end
