#!/usr/bin/ruby
require "libfield"
require "libframe"
require "libstream"

# Rsp Methods
# Input  : upd block(frame,time)
# Output : Field
module Frm
  module Rsp
    # @< (base),(prefix)
    # @ cobj,sel,fds,frame,fary,cc
    def self.extended(obj)
      Msg.type?(obj,Field::Var,Var::File)
    end

    # Command::Item is needed which includes response_id and cmd_parameters
    def ext_rsp(cobj,db)
      init_ver('FrmRsp',6)
      @cobj=Msg.type?(cobj,Command)
      @db=Msg.type?(db,Db)
      self['ver']=db['version'].to_i
      @sel=Hash[db[:rspframe]]
      @fds=db[:response][:select]
      @frame=Frame.new(db['endian'],db['ccmethod'])
      # Field Initialize
      self['val']||=db[:field][:select].deep_copy
      self
    end

    # Block accepts [frame,time]
    # Result : executed block or not
    def upd
      if rid=@cobj.current[:response]
        @sel[:select]=@fds[rid]|| Msg.cfg_err("No such response id [#{rid}]")
        hash=yield
        self['time']=hash['time']
        setframe(hash['data'])
        true
      else
        verbose{"Send Only"}
        @sel[:select]=nil
        false
      end
    end

    def upd_logline(str)
      res=Logging.set_logline(str)
      @cobj.setcmd(res['cmd'].split(':'))
      upd{res}
    end

    private
    def setframe(frame)
      Msg.com_err("No Response") unless frame
      if tm=@sel['terminator']
        frame.chomp!(eval('"'+tm+'"'))
        verbose{"Remove terminator:[#{frame}] by [#{tm}]" }
      end
      if dm=@sel['delimiter']
        @fary=frame.split(eval('"'+dm+'"'))
        verbose{"Split:[#{frame}] by [#{dm}]" }
      else
        @fary=[frame]
      end
      @frame.set(@fary.shift)
      getfield_rec(@sel[:main])
      if cc=unset('cc') #Field::unset
        cc == @cc || Msg.com_err("Verify:CC Mismatch <#{cc}> != (#{@cc})")
        verbose{"Verify:CC OK <#{cc}>"}
      end
      verbose{"Rsp/Update(#{self['time']})"} #Field::get
      self
    end

    # Process Frame to Field
    def getfield_rec(e0)
      e0.each{|e1|
        case e1
        when 'ccrange'
          begin
            verbose(1){"Entering Ceck Code Node"}
            @frame.mark
            getfield_rec(@sel[:ccrange])
            @cc = @frame.checkcode
          ensure
            verbose(-1){"Exitting Ceck Code Node"}
          end
        when 'select'
          begin
            verbose(1){"Entering Selected Node"}
            getfield_rec(@sel[:select])
          ensure
            verbose(-1){"Exitting Selected Node"}
          end
        when Hash
          frame_to_field(e1){ cut(e1) }
        end
      }
    end

    def frame_to_field(e0)
      verbose(1){"Field:#{e0['label']}"}
      if e0[:index]
        # Array
        akey=e0['assign'] || Msg.cfg_err("No key for Array")
        # Insert range depends on command param
        idxs=e0[:index].map{|e1|
          @cobj.current.subst(e1['range'])
        }
        begin
          verbose(1){"Array:[#{akey}]:Range#{idxs}"}
          self['val'][akey]=mk_array(idxs,get(akey)){yield}
        ensure
          verbose(-1){"Array:Assign[#{akey}]"}
        end
      else
        #Field
        data=yield
        if akey=e0['assign']
          self['val'][akey]=data
          verbose{"Assign:[#{akey}] <- <#{data}>"}
        end
      end
    ensure
      verbose(-1){"Field:End"}
    end

    def mk_array(idx,field)
      # make multidimensional array
      # i.e. idxary=[0,0:10,0] -> @field['val'][0][0][0] .. @field['val'][0][10][0]
      return yield if idx.empty?
      fld=field||[]
      f,l=idx[0].split(':').map{|i| eval(i)}
      Range.new(f,l||f).each{|i|
        fld[i] = mk_array(idx[1..-1],fld[i]){yield}
        verbose{"Array:Index[#{i}]=#{fld[i]}"}
      }
      fld
    end

    def cut(e)
      @frame.cut(e) || @frame.set(@fary.shift).cut(e) || ''
    end
  end
end

class Field::Var
  def ext_rsp(cobj,db)
    extend(Frm::Rsp).ext_rsp(cobj,db)
  end
end

if __FILE__ == $0
  require "liblocdb"
  require "libfrmcmd"
  Msg::GetOpts.new("",{'m' => 'merge file','l' => 'get from logline'})
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
  cobj=Command.new
  svdom=cobj.add_domain('sv')
  svdom['ext']=Frm::ExtGrp.new(fdb)
  cobj.setcmd(cmd.split(':'))
  field=Field::Var.new.ext_file(fdb['site_id'])
  field.load if $opt['m']
  field.ext_rsp(cobj,fdb)
  field.upd{res}
  puts field
  exit
end
