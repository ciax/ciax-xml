#!/usr/bin/env ruby
require 'libvarx'
module CIAX
  # Variable status data
  class Varx
    # Tag list with updating
    class TagList < Arrayx
      def initialize(filename)
        @filename = filename
        super()
      end

      def upd
        replace(Dir.glob(@filename))
        map! { |f| f.slice(/.+_(.+)\.json/, 1) }
        sort!
      end
    end

    # File I/O feature
    module JFile
      attr_reader :tag_list
      def self.extended(obj)
        Msg.type?(obj, Varx)
      end

      # Use @preload (STDIN data) if exists
      #  i.e. Initialy, data get from STDIN (@preload)
      #       -> get id from @preload
      #       -> make skeleton with dbi
      #       -> deep_update by @preload
      def load(tag = nil)
        if !tag && @preload
          verbose { 'Load from Preloading' }
          deep_update(@preload)
          @preload = nil
        else
          deep_update(__read_json(tag))
        end
        cmt
      end

      def ext_save
        extend(JSave).ext_save
      end

      private

      def _ext_local_file(dir = nil)
        verbose { "Initiate File Feature [#{base_name}]" }
        @id || cfg_err('No ID')
        @jsondir = vardir(dir || 'json')
        @cfile = base_name # Current file name
        @tag_list = TagList.new(@jsondir + __file_name('*'))
        self
      end

      def __file_name(tag = nil)
        base_name(tag) + '.json'
      end

      def ___chk_tag(tag = nil)
        return __file_name unless tag
        return __file_name(tag) if tag_list.include?(tag)
        par_err("No such Tag [#{tag}]")
        nil
      end

      def __read_json(tag = nil)
        @cfile = ___chk_tag(tag)
        jverify(loadfile(@jsondir + @cfile), @cfile)
      rescue CommError
        show_err
        self
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
        @cmt_procs.append(self, :save) { save }
        self
      end

      def save(tag = nil)
        __write_json(to_j, tag)
      end

      def save_partial(keyary, tag = nil)
        tag ||= (tag_list.map(&:to_i).max + 1)
        # id is tag, this is Mark's request
        jstr = pick(
          keyary, time: self[:time], id: self[:id], data_ver: self[:data_ver]
        ).to_j
        msg("File Saving for [#{tag}]")
        __write_json(jstr, tag)
      end

      # Load without Header which can be remain forever on the saving feature
      def load_partial(tag = nil)
        deep_update(__read_json(tag))
        cmt
      end

      def mklink(tag = 'latest')
        # Making 'latest' link
        save
        sname = rmlink(tag)
        ::File.symlink(@jsondir + __file_name, sname)
        verbose { "File Symboliclink to [#{sname}]" }
        self
      end

      def rmlink(tag)
        sname = vardir('json') + "#{@type}_#{tag}.json"
        ::File.unlink(sname) if ::File.exist?(sname)
        sname
      end

      private

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
        verbose { " -- json data (#{jstr}) is empty at saving" } if jstr.empty?
        return if @thread == Thread.current
        verbose { 'File Saving from Multiple Threads' }
      end
    end
  end
end
