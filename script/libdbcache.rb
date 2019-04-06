#!/usr/bin/env ruby
require 'libmsg'

module CIAX
  # Cache is available
  module Db
    # DB Cache
    class Cache
      include Msg
      def initialize(type)
        super()
        verbose { 'Initiate Cache' }
        @type = type
      end

      # Returns Db::Item(command list) or Disp(site list)
      def get(id)
        @cbase = "#{@type}-#{id}"
        @cachefile = vardir('cache') + "#{@cbase}.mar"
        if ___use_cache?
          ___load_cache
        else
          ___save_cache(yield)
        end
      end

      private

      def ___save_cache(res)
        open(@cachefile, 'w') do |f|
          f << Marshal.dump(res)
          verbose { "Saved (#{@cbase})" }
        end
        res
      end

      def ___load_cache
        verbose { "Loading (#{@cbase})" }
        begin
          # Used Marshal for symbol keys
          Marshal.load(IO.read(@cachefile))
        rescue ArgumentError # if empty
          Hashx.new
        end
      end

      # To scan all
      def ___use_cache?
        !(___envnocache? || ___nomar? || ___xmlnewer? || ___rbnewer?)
      end

      def ___envnocache?
        return unless ENV['NOCACHE']
        verbose { "#{@type} ENV['NOCACHE'] is set" }
        true
      end

      def ___nomar?
        return if test('e', @cachefile)
        verbose { "#{@type} MAR file(#{@cbase}) not exist" }
        true
      end

      def ___xmlnewer?
        __file_newer?('Xml', Msg.xmlfiles(@type))
      end

      def ___rbnewer?
        __file_newer?('Rb', $LOADED_FEATURES.grep(/#{__dir__}/))
      end

      def __file_newer?(cap, ary)
        latest = ary.max_by { |f| File.mtime(f) }
        return unless test('>', latest, @cachefile)
        verbose do
          format('%s %s(%s) is newer than (%s)',
                 @type, cap, latest.split('/').last, @cbase)
        end
        true
      end
    end
  end
end
