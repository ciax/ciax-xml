#!/usr/bin/env ruby
require 'libinsdb'
require 'libfrmstat'

module CIAX
  # Application Layer
  #  cmt_procs
  #  1. time setting
  #  2. convert
  #  3. sym
  #  4. save
  module App
    # Status Data
    # All elements of @data are String
    class Status < Statx
      include Dic
      include DicToken
      attr_reader :field
      # dbi can be Ins::Db or ID for new Db
      def initialize(dbi = nil, field = nil)
        super('status', dbi, Ins::Db)
        # exclude alias from index
        @adbs = @dbi[:status]
        @adbsi = @adbs[:index].reject { |_k, v| v[:ref] }
        ext_dic(:data) { Hashx.new(@adbsi).skeleton }
        %i(class msg).each { |k| self[k] ||= Hashx.new }
        ___init_field(field)
      end

      # set vars by csv
      def str_update(str)
        str.split(',').each do |tkn|
          _dic.repl(*tkn.split('='))
        end
        self
      end

      private

      # For element of SubStat
      def ___init_field(field)
        return unless @dbi[:dev_id]
        @field = type_gen(field, Frm::Field) { |mod| mod.new(@dbi[:dev_id]) }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id]', options: 'h') do |opt, args|
        puts Status.new(args).cmode(opt.host)
      end
    end
  end
end
