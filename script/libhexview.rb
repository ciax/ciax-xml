#!/usr/bin/ruby
require 'libprompt'
require 'libhexdb'
module CIAX
  # Ascii Hex Pack
  module Hex
    # View class
    class View < Varx
      # sv_stat should have server status (isu,watch,exe..) like App::Exe
      def initialize(stat, hdb = nil, sv_stat = nil)
        @stat = type?(stat, App::Status)
        super('hex', @stat[:id], @stat[:ver])
        @dbi = (hdb || Db.new).get(@stat.dbi[:app_id])
        id = self[:id] || args_err("NO ID(#{id}) in Stat")
        @sv_stat = sv_stat || Prompt.new('site', id)
        vmode('x')
        ___init_cmt_procs
      end

      def to_x
        self[:hexpack]
      end

      private

      def ___init_cmt_procs
        init_time2cmt(@stat)
        @cmt_procs << proc do
          self[:hexpack] = ___get_header + ___get_body
        end
        ___init_propagates
      end

      def ___init_propagates
        @sv_stat.cmt_procs << proc { _cmt_propagate('Prompt') }
        @stat.cmt_procs << proc { _cmt_propagate('Status') }
        cmt
      end

      def _cmt_propagate(mod)
        verbose { "Propagate #{mod}#cmt -> Hex::View#cmt" }
        cmt
      end

      # Server Status
      def ___get_header
        ary = ['%', self[:id]]
        ary << b2e(@sv_stat.up?(:udperr))
        ary << b2i(@sv_stat.up?(:event))
        ary << b2i(@sv_stat.up?(:busy))
        ary << b2e(@sv_stat.up?(:comerr))
        ary.join('')
      end

      def ___get_body
        return '' unless (hdb = @dbi[:hexpack])
        str = ''
        if hdb[:packs]
          str << ___packed(hdb[:packs])
        elsif hdb[:fields]
          str << ___mk_frame(hdb)
        end
        str
      end

      def ___packed(packs)
        packs.map do |hash|
          binstr = ___mk_bit(hash)
          pkstr = hash[:code] + hash[:length]
          [binstr].pack(pkstr).unpack('h')[0]
        end.join
      end

      def ___mk_bit(db)
        db[:bits].map do |hash|
          key = hash[:ref]
          cfg_err("No such key [#{key}]") unless @stat[:data].key?(key)
          dat = @stat[:data][key]
          verbose { "Get from Status #{key} = #{dat}" }
          dat
        end.join
      end

      def ___mk_frame(db)
        db[:fields].map do |hash|
          key = hash[:ref]
          cfg_err("No such key [#{key}]") unless @stat[:data].key?(key)
          dat = ___padding(hash, @stat[:data][key])
          verbose { "Get from Status #{key} = #{dat}" }
          dat
        end.join
      end

      def ___padding(hash, val)
        len = hash[:length].to_i
        type = hash[:type].to_s.to_sym
        pfx = { float: '.2f', int: 'd', binary: 'b' }[type]
        if pfx
          ___fmt_num(pfx, len, val)
        else
          val.to_s.rjust(len, '*')[0, len]
        end
      end

      def ___fmt_num(sfx, len, val)
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
        puts View.new(stat)
      end
    end
  end
end