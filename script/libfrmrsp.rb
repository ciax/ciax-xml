#!/usr/bin/ruby
require 'libfield'
require 'libframe'
require 'libstream'

# Rsp Methods
# Input  : upd block(frame,time)
# Output : Field
module CIAX
  # Frame Layer
  module Frm
    # Frame Response module
    module Rsp
      # @< (base),(prefix)
      # @ cobj,sel,fds,frame,fary,cc
      def self.extended(obj)
        Msg.type?(obj, Field)
      end

      # Ent is needed which includes response_id and cmd_parameters
      def ext_local_rsp(stream)
        @stream = type?(stream, Hash)
        type?(@dbi, Dbi)
        fdbr = @dbi[:response]
        @skel = fdbr[:frame]
        @fds = fdbr[:index]
        sp = type?(@dbi[:stream], Hash)
        # Frame structure:
        #   main(total){ ccrange{ body(selected str) } }
        @frame = Frame.new(sp[:endian], sp[:ccmethod], sp[:terminator])
        # terminator: frame pointer will jump to terminator
        #   when no length or delimiter is specified
        self
      end

      # Convert with corresponding cmd
      def conv(ent)
        rid = type?(ent, Cmd::Entity)[:response]
        @fds.key?(rid) || Msg.cfg_err("No such response id [#{rid}]")
        _make_sel(ent, rid)
        @frame.set(@stream.binary)
        _make_data(rid)
        verbose { 'Propagate Stream#rcv Field#conv(cmt)' }
        self
      ensure
        time_upd
        cmt
      end

      private

      def time_upd
        super(@stream[:time])
      end

      # sel structure:
      #   { terminator, :main{}, :body{} <- changes on every upd }
      def _make_sel(ent, rid)
        @sel = Hash[@skel]
        @sel.update(@fds[rid])
        @sel[:body] = ent.deep_subst(@sel[:body])
        verbose { "Selected DB for #{rid}\n" + @sel.inspect }
      end

      def _make_data(rid)
        @cache = self[:data].deep_copy
        if @fds[rid].key?(:noaffix)
          getfield_rec(['body'])
        else
          getfield_rec(@sel[:main])
          @frame.cc.check(@cache.delete('cc'))
        end
        self[:data] = @cache
      end

      # Process Frame to Field
      def getfield_rec(e0)
        e0.each do|e1|
          if e1.is_a?(Hash)
            frame_to_field(e1) { @frame.cut(e1) }
          else
            _make_rec(e1)
          end
        end
      end

      def _make_rec(e1)
        case e1
        when 'ccrange'
          @frame.cc.enclose { getfield_rec(@sel[:ccrange]) }
        when 'body'
          getfield_rec(@sel[:body] || [])
        when 'echo' # Send back the command string
          @frame.cut(label: 'Command Echo', val: @echo)
        end
      end

      def frame_to_field(e0)
        enclose("#{e0[:label]}", 'Field:End') do
          if e0[:index]
            _ary_field(e0) { yield }
          else
            _str_field(e0, yield)
          end
        end
      end

      # Field
      def _str_field(e0, data)
        return unless (akey = e0[:assign])
        @cache[akey] = data
        verbose { "Assign:[#{akey}] <- <#{data}>" }
      end

      # Array
      def _ary_field(e0)
        akey = e0[:assign] || Msg.cfg_err('No key for Array')
        # Insert range depends on command param
        idxs = e0[:index].map do|e1|
          e1[:range] || "0:#{e1[:size].to_i - 1}"
        end
        enclose("Array:[#{akey}]:Range#{idxs}", "Array:Assign[#{akey}]") do
          @cache[akey] = mk_array(idxs, self[:data][akey]) { yield }
        end
      end

      def mk_array(idx, field)
        # make multidimensional array
        # i.e. idxary=[0,0:10,0] -> @data[0][0][0] .. @data[0][10][0]
        return yield if idx.empty?
        fld = field || []
        f, l = idx[0].split(':').map { |i| expr(i) }
        Range.new(f, l || f).each do|i|
          fld[i] = mk_array(idx[1..-1], fld[i]) { yield }
          verbose { "Array:Index[#{i}]=#{fld[i]}" }
        end
        fld
      end
    end

    # Field class
    class Field
      def ext_local_rsp(stream)
        extend(Frm::Rsp).ext_local_rsp(stream)
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfrmcmd'
      ConfOpts.new('< logline', 'm', m: 'merge file') do |cfg, _args, opt|
        fail(InvalidARGS, '  Need Input File') if STDIN.tty?
        str = gets(nil) || exit
        res = JsLog.read(str)
        id = res[:id]
        cid = res[:cmd]
        dbi = Dev::Db.new.get(id)
        field = Field.new(dbi).ext_local_rsp(res)
        field.ext_local_file.auto_save if opt[:m]
        if cid
          cfg[:field] = field
          # dbi.pick alreay includes :command, :version
          cobj = Index.new(cfg, dbi.pick(%i(stream)))
          cobj.add_rem.add_ext(Ext)
          ent = cobj.set_cmd(cid.split(':'))
          field.conv(ent)
        end
        puts field
      end
    end
  end
end
