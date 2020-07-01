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
      include DicToken
      attr_reader :sub_stat
      # dbi can be Ins::Db or ID for new Db
      def initialize(dbi = nil, field = nil)
        super('status', dbi, Ins::Db)
        # exclude alias from index
        @adbs = @dbi[:status]
        @adbsi = @adbs[:index].reject { |_k, v| v[:ref] }
        ext_dic(:data) { Hashx.new(@adbsi).skeleton }
        %i[class msg].each { |k| self[k] ||= Hashx.new }
        ___init_field(field)
      end

      # Get with token
      def get(id)
        token = id.sub(%r{data/}, '')
        return super unless %r{/} =~ token
        cat = $`.to_sym
        cfg_err('No such entry [%s]', cat) unless key?(cat)
        self[cat].get($')
      end

      # set vars by csv
      def str_update(str)
        str.split(',').each do |tkn|
          _dic.repl(*tkn.split('='))
        end
        cmt
      end

      ## For macro step
      # Getting real value in [data:id]
      def pick_val(ref)
        warning('No form specified') unless ref[:form]
        # form = 'data', 'class' or 'msg' in Status
        form = (ref[:form] || :data).to_sym
        var = ref[:var]
        data = self[form]
        warning('No [%s] in Status[%s]', var, form) unless data.key?(var)
        data[var]
      end

      private

      # For element of SubStat
      def ___init_field(field)
        if @dbi.key?(:dev_id)
          @sub_stat = type_gen(field, Frm::Field, @dbi[:dev_id])
        else
          # Dummy mode
          init_time2cmt
        end
      end
    end

    if $PROGRAM_NAME == __FILE__
      Opt::Get.new('[id]', options: 'h') do |opt, args|
        puts Status.new(args).cmode(opt.host)
      end
    end
  end
end
