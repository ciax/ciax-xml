#!/usr/bin/ruby
require 'libvarx'
require 'libprompt'
module CIAX
  # Ascii Hex Pack
  module Hex
    # View class
    class View < Varx
      # hint should have server status (isu,watch,exe..) like App::Exe
      def initialize(stat, sv_stat = nil)
        @stat = type?(stat, App::Status)
        super('hex', @stat['id'], @stat['ver'])
        # Server Status
        id = self['id'] || id_err("NO ID(#{id}) in Stat")
        @sv_stat = type?(sv_stat || Prompt.new('site', id), Prompt)
        @list = _get_sdb_(id)
        @vmode = :x
        _init_upd_
      end

      def self.sdb(id)
        file = ENV['HOME'] + "/config/sdb_#{id}.txt"
        test('r', file) && file
      end

      def to_x
        self['hex']
      end

      def to_s
        if @vmode == :x
          to_x
        else
          super
        end
      end

      private

      def upd_core
        _get_body_
        self['hex'] = _get_header_ + @str
        self
      end

      def _get_header_
        ary = ['%', self['id']]
        ary << b2e(@sv_stat[:udperr])
        ary << b2i(@sv_stat[:event])
        ary << b2i(@sv_stat[:isu])
        ary << b2e(@sv_stat[:comerr])
        ary.join('')
      end

      def _get_body_
        _set_var_
        @list.each do|key, title, len, type|
          if /%pck/ =~ key
            _set_var_(len)
          elsif @pck > 0
            @str << _get_bin_(key)
          else
            @str << _get_str_(key, title, len, type)
          end
        end
      end

      def _set_var_(pck = 0, bin = 0)
        @pck = pck.to_i
        @bin = bin.to_i
        @str = ''
      end

      def _get_bin_(key)
        @bin += @stat.get(key).to_i
        @bin << 1
        @pck -= 1
        format('%x', @bin) if @pck == 0
      end

      def _get_str_(key, title, len, type)
        v = @stat.get(key)
        if v
          str = _get_elem_(type, len, v)
          verbose { "#{title}/#{type}(#{len}) = #{str}" }
        else
          str = '*' * len.to_i
        end
        # str can exceed specified length
        str = str[0, len.to_i]
        verbose { "add '#{str}' as #{key}" }
        str
      end

      def _get_sdb_(id)
        file = View.sdb(id) || id_err("Hex/Can't found sdb_#{id}.txt")
        open(file) do|f|
          f.readlines.grep(/^[^#].+/).map do |line|
            line.split(',')
          end
        end
      end

      def _init_upd_
        @sv_stat.post_upd_procs << proc do
          verbose { 'Propagate Prompt#upd -> Hex::View#upd' }
          upd
        end
        @stat.post_upd_procs << proc do
          verbose { 'Propagate Status#upd -> Hex::View#upd' }
          upd
        end
        upd
      end

      def _get_elem_(type, len, val)
        case type
        when /FLOAT/
          format("%0#{len}.2f", val.to_f)
        when /INT/
          format("%0#{len}d", val.to_i)
        when /BINARY/
          format("%0#{len}b", val.to_i)
        else
          format("%#{len}s", val)
        end
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
      begin
        fail(InvalidID) if STDIN.tty?
        stat = App::Status.new.read
        puts View.new(stat).upd
      rescue InvalidID
        Msg.usage(' < status_file')
      end
    end
  end
end
