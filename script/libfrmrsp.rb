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
      def ext_rsp
        type?(@dbi, Dbi)
        fdbr = @dbi[:response]
        @skel = fdbr[:frame]
        # @sel structure: { terminator, :main{}, :body{} <- changes on every upd }
        @fds = fdbr[:index]
        sp = @dbi[:stream]
        # Frame structure: main(total){ ccrange{ body(selected str) } }
        @frame = Frame.new(sp[:endian], sp[:ccmethod], sp[:terminator])
        # terminator: frame pointer will jump to terminator if no length or delimiter is specified
        self
      end

      # Convert with corresponding cmd
      def conv(ent, stream)
        @sel = Hash[@skel]
        self[:time] = type?(stream, Hash)[:time]
        rid = type?(ent, Entity)[:response]
        @fds.key?(rid) || Msg.cfg_err("No such response id [#{rid}]")
        @sel.update(@fds[rid])
        @sel[:body] = ent.deep_subst(@sel[:body])
        verbose { "Selected DB for #{rid}\n" + @sel.inspect }
        @frame.set(stream.binary)
        @cache = self[:data].deep_copy
        if @fds[rid].key?(:noaffix)
          getfield_rec(['body'])
        else
          getfield_rec(@sel[:main])
          @frame.cc_check(@cache.delete('cc'))
        end
        self[:data] = @cache
        verbose { 'Propagate Stream#rcv Field#upd' }
        self
      ensure
        post_upd
      end

      private

      # Process Frame to Field
      def getfield_rec(e0)
        e0.each do|e1|
          case e1
          when 'ccrange'
            enclose('Entering Ceck Code Node', 'Exitting Ceck Code Node') do
              @frame.cc_mark
              getfield_rec(@sel[:ccrange])
              @frame.cc_set
            end
          when 'body'
            enclose('Entering Body Node', 'Exitting Body Node') do
              getfield_rec(@sel[:body] || [])
            end
          when 'echo' # Send back the command string
            verbose { "Set Command Echo [#{@echo.inspect}]" }
            @frame.cut(label: 'Command Echo', val: @echo)
          when Hash
            frame_to_field(e1) { @frame.cut(e1) }
          end
        end
      end

      def frame_to_field(e0)
        enclose("#{e0[:label]}", 'Field:End') do
          if e0[:index]
            # Array
            akey = e0[:assign] || Msg.cfg_err('No key for Array')
            # Insert range depends on command param
            idxs = e0[:index].map do|e1|
              e1[:range] || "0:#{e1[:size].to_i - 1}"
            end
            enclose("Array:[#{akey}]:Range#{idxs}", "Array:Assign[#{akey}]") do
              @cache[akey] = mk_array(idxs, self[:data][akey]) { yield }
            end
          else
            # Field
            data = yield
            if (akey = e0[:assign])
              @cache[akey] = data
              verbose { "Assign:[#{akey}] <- <#{data}>" }
            end
          end
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
      def ext_rsp
        extend(Frm::Rsp).ext_rsp
      end
    end

    if __FILE__ == $PROGRAM_NAME
      require 'libfrmcmd'
      OPT.parse('m', m: 'merge file')
      OPT.usage('(opt) < logline') if STDIN.tty?
      str = gets(nil) || exit
      res = JsLog.read(str)
      id = res[:id]
      cid = res[:cmd]
      dbi = Dev::Db.new.get(id).cover
      field = Field.new(dbi).ext_rsp
      field.ext_file.auto_save if OPT[:m]
      if cid
        cfg = Config.new.update(dbi: dbi, field: field)
        cobj = Index.new(cfg)
        cobj.add_rem.add_ext(Ext)
        ent = cobj.set_cmd(cid.split(':'))
        field.conv(ent, res)
      end
      puts field
    end
  end
end
