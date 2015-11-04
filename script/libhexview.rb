#!/usr/bin/ruby
# Ascii Pack
require 'libvarx'
require 'libprompt'

module CIAX
  module Hex
    class View < Varx
      # hint should have server status (isu,watch,exe..) like App::Exe
      def initialize(stat, sv_stat = nil)
        @stat = type?(stat, App::Status)
        super('hex', @stat['id'], @stat['ver'])
        # Server Status
        id = self['id'] || id_err("NO ID(#{id}) in Stat")
        @sv_stat = sv_stat || Prompt.new(id)
        file = View.sdb(id) || id_err("Hex/Can't found sdb_#{id}.txt")
        @res = ['%', id, '_', '0', '0', '_', '']
        @list = []
        @vmode = 'x'
        open(file) do|f|
          while (line = f.gets)
            ary = line.split(',')
            case line
            when /^[#]/, /^$/
            else
              @list << ary
            end
          end
        end
        @sv_stat.post_upd_procs << proc do
          verbose { 'Propagate Prompt#upd -> Hex::View#upd' }
          upd
        end
        @stat.post_upd_procs << proc do
          verbose { 'Propagate Status#upd -> Hex::View#upd' }
          upd
        end
        upd
        self
      end

      def self.sdb(id)
        file = ENV['HOME'] + "/config/sdb_#{id}.txt"
        test('r', file) && file
      end

      def upd_core
        @res[2] = b2e(@sv_stat['udperr'])
        @res[3] = b2i(@sv_stat['event'])
        @res[4] = b2i(@sv_stat['isu'])
        @res[5] = b2e(@sv_stat['comerr'])
        @res[6] = ''
        pck = 0
        bin = 0
        @list.each do|key, title, len, type|
          len = len.to_i
          if key =~ '%pck'
            pck = len
            bin = 0
          elsif pck > 0
            bin += @stat.get(key).to_i
            bin << 1
            pck -= 1
            @res[6] << format('%x', bin) if pck == 0
          else
            v = @stat.get(key)
            if v
              str = get_elem(type, len, v)
              verbose { "#{title}/#{type}(#{len}) = #{str}" }
            else
              str = '*' * len
            end
            # str can exceed specified length
            str = str[0, len]
            verbose { "add '#{str}' as #{key}" }
            @res[6] << str
          end
        end
        self['hex'] = @res.join('')
        self
      end

      def to_x
        self['hex']
      end

      def to_s
        case @vmode
        when 'x'
          to_x
        else
          super
        end
      end

      private

      def get_elem(type, len, val)
        case type
        when /FLOAT/
          str = format("%0#{len}.2f", val.to_f)
        when /INT/
          str = format("%0#{len}d", val.to_i)
        when /BINARY/
          str = format("%0#{len}b", val.to_i)
        else
          str = format("%#{len}s", val)
        end
        str
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
