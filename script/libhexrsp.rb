#!/usr/bin/ruby
require 'libprompt'
require 'libhexdb'
module CIAX
  # Ascii Hex Pack
  module Hex
    # View class
    class Rsp < Varx
      # sv_stat should have server status (isu,watch,exe..) like App::Exe
      def initialize(stat, hdb = nil, sv_stat = nil)
        @stat = type?(stat, App::Status)
        super('hex', @stat[:id], @stat[:ver])
        @dbi = (hdb || Db.new).get(@stat.dbi[:app_id])
        id = self[:id] || args_err("NO ID(#{id}) in Stat")
        @sv_stat = sv_stat || Prompt.new('site', id)
        vmode('x')
        _init_cmt_procs_
      end

      def to_x
        self[:hexpack]
      end

      private

      def _init_cmt_procs_
        init_time2cmt(@stat)
        @cmt_procs << proc do
          self[:hexpack] = _get_header_ + _get_body_
        end
        _init_propagates_
      end

      def _init_propagates_
        @sv_stat.cmt_procs << proc { _cmt_propagate('Prompt') }
        @stat.cmt_procs << proc { _cmt_propagate('Status') }
        cmt
      end

      def _cmt_propagate(mod)
        verbose { "Propagate #{mod}#cmt -> Hex::Rsp#cmt" }
        cmt
      end

      # Server Status
      def _get_header_
        ary = ['%', self[:id]]
        ary << b2e(@sv_stat.up?(:udperr))
        ary << b2i(@sv_stat.up?(:event))
        ary << b2i(@sv_stat.up?(:busy))
        ary << b2e(@sv_stat.up?(:comerr))
        ary.join('')
      end

      def _get_body_
        return '' unless (hdb = @dbi[:hexpack])
        str = ''
        if hdb[:packs]
          str << _packed_(hdb[:packs])
        elsif hdb[:fields]
          str << _mk_frame_(hdb)
        end
        str
      end

      def _packed_(packs)
        packs.map do |hash|
          binstr = _mk_bit_(hash)
          pkstr = hash[:code] + hash[:length]
          [binstr].pack(pkstr).unpack('h')[0]
        end.join
      end

      def _mk_bit_(db)
        db[:bits].map do |hash|
          key = hash[:ref]
          cfg_err("No such key [#{key}]") unless @stat[:data].key?(key)
          dat = @stat[:data][key]
          verbose { "Get from Status #{key} = #{dat}" }
          dat
        end.join
      end

      def _mk_frame_(db)
        db[:fields].map do |hash|
          key = hash[:ref]
          cfg_err("No such key [#{key}]") unless @stat[:data].key?(key)
          dat = _padding_(hash, @stat[:data][key])
          verbose { "Get from Status #{key} = #{dat}" }
          dat
        end.join
      end

      def _padding_(hash, val)
        len = hash[:length].to_i
        type = hash[:type].to_s.to_sym
        pfx = { float: '.2f', int: 'd', binary: 'b' }[type]
        if pfx
          _fmt_num_(pfx, len, val)
        else
          val.to_s.rjust(len, '*')[0, len]
        end
      end

      def _fmt_num_(sfx, len, val)
        num = /f/ =~ sfx ? val.to_f : val.to_i
        format("%0#{len}#{sfx}", num)[0, len]
      end

      def b2i(b) # Boolean to Integer (1,0)
        b ? '1' : '0'
      end

      def b2e(b) # Boolean to Error (E,_)
        b ? 'E' : '_'
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libinsdb'
      require 'libstatus'
      GetOpts.new(' < status_file') do
        stat = App::Status.new.ext_local_file
        puts Rsp.new(stat)
      end
    end
  end
end
