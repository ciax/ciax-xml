#!/usr/bin/ruby
module CIAX
  # Variable status data
  class Varx
    # File I/O feature
    module JFile
      def self.extended(obj)
        Msg.type?(obj, Varx)
      end

      def ext_local_file(dir = nil)
        verbose { "Initiate File Feature [#{base_name}]" }
        @id || cfg_err('No ID')
        @jsondir = vardir(dir || 'json')
        @cfile = base_name # Current file name
        self
      end

      def load(tag = nil)
        replace(__read_json(tag))
        cmt
      end

      def ext_save
        extend(JSave).ext_save
      end

      private

      def __file_name(tag = nil)
        base_name(tag) + '.json'
      end

      def __tag_list
        Dir.glob(@jsondir + __file_name('*')).map do |f|
          f.slice(/.+_(.+)\.json/, 1)
        end.sort
      end

      def ___chk_tag(tag = nil)
        return __file_name unless tag
        list = __tag_list
        return __file_name(tag) if list.include?(tag)
        par_err('No such Tag', "Tag=#{list}")
        nil
      end

      def __read_json(tag = nil)
        @cfile = ___chk_tag(tag)
        jload(@jsondir + @cfile)
      end

      # JSON file module functions
      module_function

      # Using for RecArc, RecDic
      def jload(fname)
        jverify(loadfile(fname))
      rescue InvalidData
        show_err
        Hashx.new
      end

      def loadfile(fname)
        check_file_stat(fname)
        open(fname) do |f|
          verbose { "Loading file [#{fname}](#{f.size})" }
          f.flock(::File::LOCK_SH)
          f.read
        end
      rescue Errno::ENOENT
        verbose { "  -- no json file (#{fname})" }
      end

      def check_file_stat(fname)
        data_err("Cant read (#{fname})") unless test('r', fname)
        return true if test('s', fname)
        warning("File empty (#{fname})")
      end
    end

    # File saving feature
    module JSave
      def self.extended(obj)
        Msg.type?(obj, JFile)
      end

      def ext_save
        verbose { "Initiate File Saving Feature [#{base_name}]" }
        @thread = Thread.current # For Thread safe
        @cmt_procs << proc { save }
        self
      end

      def save(tag = nil)
        __write_json(to_j, tag)
      end

      def save_partial(keyary, tag = nil)
        tag ||= (__tag_list.map(&:to_i).max + 1)
        # id is tag, this is Mark's request
        jstr = pick(
          keyary, time: self[:time], id: self[:id], ver: self[:ver]
        ).to_j
        msg("File Saving for [#{tag}]")
        __write_json(jstr, tag)
      end

      # Load without Header which can be remain forever on the saving feature
      def load_partial(tag = nil)
        hash = __read_json(tag)
        ___match_version?(hash) && deep_update(hash)
        cmt
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

      # Data Version check, no read if different
      # (otherwise old version number remain as long as the file exists)
      def ___match_version?(hash)
        ary = _val_diff?(:ver, hash)
        return hash unless ary
        warning(format('File data version mismatch <%s> for [%s]', *ary))
        false
      end

      def __write_json(jstr, tag = nil)
        ___write_notice(jstr)
        @cfile = __file_name(tag)
        open(@jsondir + @cfile, 'w') do |f|
          f.flock(::File::LOCK_EX)
          f << jstr
          verbose { "File [#{@cfile}](#{f.size}) is Saved at #{self[:time]}" }
        end
        self
      end

      def ___write_notice(jstr)
        verbose(jstr.empty?) { " -- json data (#{jstr}) is empty at saving" }
        verbose(@thread != Thread.current) do
          'File Saving from Multiple Threads'
        end
      end
    end
  end
end
