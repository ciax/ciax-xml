#!/usr/bin/env ruby
require 'libstatx'
require 'libdic'
require 'libdevdb'

module CIAX
  # Frame Layer
  module Stream
    # Response Frame DB
    class Frame < Statx
      include Dic
      def initialize(dbi = nil)
        super('frame', dbi, Dev::Db)
        ext_dic(:data) { Hashx.new(@dbi[:response][:index]).skeleton }
        # For stream log reading from stdin
        put(delete(:cmd), delete(:base64)) if key?(:cmd)
      end

      def get(id)
        val = super
        dec64(val) if val
      end

      def conv(hash)
        return self if type?(hash, Hashx).empty?
        update(hash.pick([:time]))
        cid = hash['cmd']
        _dic.update(cid => hash['base64'])
        verbose do
          cfmt('Conversion Stream -> Frame %S %S', cid, time)
        end
        cmt
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id]', options: 'h') do |opt, args|
        puts Frame.new(args).cmode(opt.host).path(args)
      end
    end
  end
end
