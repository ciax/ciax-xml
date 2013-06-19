#!/usr/bin/ruby
require "libfield"
require "libframe"
require "libstream"

# Rsp Methods
# Input  : upd block(frame,time)
# Output : Field
module CIAX
  module Frm
    module Rsp
      include File
      # @< (base),(prefix)
      # @ cobj,sel,fds,frame,fary,cc
      def self.extended(obj)
        Msg.type?(obj,Field)
      end

      # Item is needed which includes response_id and cmd_parameters
      def ext_rsp(db)
        @ver_color=6
        @db=type?(db,Db)
        self['ver']=db['version'].to_i
        @sel=Hash[db[:rspframe]]
        @fds=db[:response][:select]
        @frame=Frame.new(db['endian'],db['ccmethod'])
        # Field Initialize
        @data.replace db[:field][:select].deep_copy if @data.empty?
        ext_fname(db['site_id'])
        self
      end

      # Block accepts [frame,time]
      # Result : executed block or not
      def upd(item)
        @current_item=type?(item,Item)
        if rid=item[:response]
          @sel[:select]=@fds[rid]|| Msg.cfg_err("No such response id [#{rid}]")
          hash=yield
          self['time']=hash['time']
          setframe(hash['data'])
          verbose("FrmRsp","Rsp/Updated(#{self['time']})") #Field::get
          super()
          true
        else
          verbose("FrmRsp","Send Only")
          @sel[:select]=nil
          false
        end
      end

      private
      def setframe(frame)
        Msg.com_err("No Response") unless frame
        if tm=@sel['terminator']
          frame.chomp!(eval('"'+tm+'"'))
          verbose("FrmRsp","Remove terminator:[#{frame}] by [#{tm}]")
        end
        if dm=@sel['delimiter']
          @fary=frame.split(eval('"'+dm+'"'))
          verbose("FrmRsp","Split:[#{frame}] by [#{dm}]")
        else
          @fary=[frame]
        end
        @frame.set(@fary.shift)
        getfield_rec(@sel[:main])
        if cc=unset('cc') #Field::unset
          cc == @cc || Msg.com_err("Verify:CC Mismatch <#{cc}> != (#{@cc})")
          verbose("FrmRsp","Verify:CC OK <#{cc}>")
        end
        self
      end

      # Process Frame to Field
      def getfield_rec(e0)
        e0.each{|e1|
          case e1
          when 'ccrange'
            verbose("FrmRsp","Entering Ceck Code Node")
            enclose{
              @frame.mark
              getfield_rec(@sel[:ccrange])
              @cc = @frame.checkcode
            }
            verbose("FrmRsp","Exitting Ceck Code Node")
          when 'select'
            verbose("FrmRsp","Entering Selected Node")
            enclose{
              getfield_rec(@sel[:select])
            }
            verbose("FrmRsp","Exitting Selected Node")
          when Hash
            frame_to_field(e1){ cut(e1) }
          end
        }
      end

      def frame_to_field(e0)
        verbose("FrmRsp","#{e0['label']}")
        enclose{
          if e0[:index]
            # Array
            akey=e0['assign'] || Msg.cfg_err("No key for Array")
            # Insert range depends on command param
            idxs=e0[:index].map{|e1|
              @current_item.subst(e1['range'])
            }
            verbose("FrmRsp","Array:[#{akey}]:Range#{idxs}")
            enclose{
              @data[akey]=mk_array(idxs,get(akey)){yield}
            }
            verbose("FrmRsp","Array:Assign[#{akey}]")
          else
            #Field
            data=yield
            if akey=e0['assign']
              @data[akey]=data
              verbose("FrmRsp","Assign:[#{akey}] <- <#{data}>")
            end
          end
        }
        verbose("FrmRsp","Field:End")
      end

      def mk_array(idx,field)
        # make multidimensional array
        # i.e. idxary=[0,0:10,0] -> @data[0][0][0] .. @data[0][10][0]
        return yield if idx.empty?
        fld=field||[]
        f,l=idx[0].split(':').map{|i| eval(i)}
        Range.new(f,l||f).each{|i|
          fld[i] = mk_array(idx[1..-1],fld[i]){yield}
          verbose("FrmRsp","Array:Index[#{i}]=#{fld[i]}")
        }
        fld
      end

      def cut(e)
        @frame.cut(e) || @frame.set(@fary.shift).cut(e) || ''
      end
    end
  end

  class Field
    def ext_rsp(db)
      extend(Frm::Rsp).ext_rsp(db)
    end
  end

  if __FILE__ == $0
    require "liblocdb"
    require "libfrmcmd"
    GetOpts.new("",{'m' => 'merge file','l' => 'get from logline'})
    if $opt['l']
      $opt.usage("-l < logline") if STDIN.tty?
      str=gets(nil) || exit
      res=Logging.set_logline(str)
      id=res['id']
      cmd=res['cmd']
      frame=res['data']
    elsif STDIN.tty? || ARGV.size < 2
      $opt.usage("(opt) [id] [cmd] < string")
    else
      id=ARGV.shift
      cmd=ARGV.shift
      res={'time'=>UnixTime.now}
      res['data']=gets(nil) || exit
    end
    fdb=Loc::Db.new.set(id)[:frm]
    fgrp=Frm::ExtGrp.new(fdb)
    item=fgrp.setcmd(cmd.split(':'))
    field=Field.new.ext_rsp(fdb)
    field.load if $opt['m']
    field.upd(item){res}
    puts field
    exit
  end
end
