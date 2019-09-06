#!/usr/bin/env ruby
require 'libprompt'
require 'libwatstat'
require 'libhexdb'
module CIAX
  # Ascii Hex Pack
  module Hex
    # View class
    class View < Varx
      # sv_stat should have server status (isu,watch,exe..) like App::Exe
      # stat contains Status (data:name ,class:name ,msg:name)
      #   + Field (field:name) + Frame (frame:name)
      def initialize(stat_pool, hdb = nil)
        # To use token omitting 'status:'
        @stat_pool = type?(stat_pool, StatPool)
        @stat = @stat_pool['event']
        super('hex', @stat[:id])
        _attr_set(@stat[:data_ver])
        @dbi = (hdb || Db.new).get(@stat.dbi[:app_id])
        @sv_stat = type?(@stat_pool[:sv_stat], Prompt)
        ___init_cmt_procs
        vmode('x')
      end

      def to_x
        ___header + ___body
      end

      private

      def ___init_cmt_procs
        propagation(@stat)
        propagation(@sv_stat)
        @cmt_procs.append(self, :hex, 1) do
          verbose { _conv_text('Field -> Hexstr', @id, time_id) }
          self[:hexpack] = to_x
        end
        cmt
      end

      # Server Status
      def ___header
        ary = ['%', self[:id]]
        ary << __b2e(__up?(:udperr))
        # Use :action flag to keep :exe 'up' between :busy and :event
        ary << __b2i(__up?(:action, :event))
        ary << __b2i(__up?(:busy))
        ary << __b2e(__up?(:comerr))
        ary.join('')
      end

      def ___body
        return '' unless (hdb = @dbi[:hexpack])
        str = ''
        if hdb[:packs]
          str << ___packed(hdb[:packs])
        elsif hdb[:fields]
          str << ___mk_frame(hdb[:fields])
        end
        str
      end

      def ___packed(packs)
        packs.map do |hash|
          bits = hash[:bits]
          binstr = ___mk_bit(bits)
          pkstr = format('%s%d', hash[:code], bits.size)
          upkstr = format('h%d', hash[:length])
          [binstr].pack(pkstr).unpack(upkstr)[0]
        end.join
      end

      def ___mk_bit(bits)
        bits.map do |hash|
          @stat_pool.get(hash[:ref])
        end.join
      end

      def ___mk_frame(fields)
        fields.map do |hash|
          ___padding(hash, @stat_pool.get(hash[:ref]))
        end.join
      end

      def ___padding(hash, val)
        len = hash[:length].to_i
        type = hash[:type].to_s.to_sym
        pfx = { float: '.2f', int: 'd', binary: 'b', hex: 'x' }[type]
        if pfx
          ___fmt_num(pfx, len, val)
        else
          str = val.to_s.tr("\n", '')
          len > 0 ? str.ljust(len, '_')[0, len] : str
        end
      end

      def ___fmt_num(sfx, len, val)
        num = /f/ =~ sfx ? val.to_f : val.to_i
        format("%0#{len}#{sfx}", num)[0, len]
      end

      def __b2i(b) # Boolean to Integer (1,0)
        b ? '1' : '0'
      end

      def __b2e(b) # Boolean to Error (E,_)
        b ? 'E' : '_'
      end

      def __up?(*ary)
        ary.any? { |k| @sv_stat.up?(k) }
      end
    end

    if __FILE__ == $PROGRAM_NAME
      Opt::Get.new('[id]', options: 'h') do |opt, args|
        event = Wat::Event.new(args).cmode(opt.host)
        stat_pool = StatPool.new(event, Prompt.new('site', event.id))
        puts View.new(stat_pool).to_x
      end
    end
  end
end
