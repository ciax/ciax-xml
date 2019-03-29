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

      def input(hash)
        _dic.update(type?(hash, Hash))
        cmt
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id]', options: 'h') do |opt, args|
        puts Frame.new(args.shift).mode(opt.host).path(args)
      end
    end
  end
end
