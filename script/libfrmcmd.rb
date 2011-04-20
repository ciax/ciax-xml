#!/usr/bin/ruby
require "libfrmmod"
require "libparam"
require "librepeat"
# Cmd Methods
class FrmCmd
  include FrmMod

  def initialize(doc,stat)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @doc,@stat=doc,stat
    @v=Verbose.new("fdb/#{@doc['id']}/cmd".upcase)
    @cache={}
    @label={}
    @response={}
    @rep=Repeat.new
    @fary=init_frame
    @par=Param.new(@label)
  end

  def setcmd(stm) # return = response select
    @id=stm.first
    @sel=@fary[@id] || @par.list_cmd
    @par.setpar(stm)
    @cid=stm.join(':')
    @cid << ':*' if /true|1/ === @sel['nocache']
    @v.msg{'Select:'+@label[@id]+"(#{@cid})"}
    self
  end

  def getframe
    return unless @id
    if cmd=@cache[@cid]
      @v.msg{"Cmd cache found [#{@cid}]"}
    else
      if @sel.key?('ccrange')
        begin
          @v.msg(1){"Entering Ceck Code Range"}
          ccstr=@sel['ccrange'].map{|a|
            @stat.subst(@par.subst(a)).split(',').map{|s|
              encode(a,s)
            }
          }.join('')
          @stat['cc']=checkcode(@sel,ccstr)
        ensure
          @v.msg(-1){"Exitting Ceck Code Range"}
        end
      end
      cmd=@sel['frame'].map{|a|
        if a == :ccrange
          ccstr
        else
          encode(a,@stat.subst(@par.subst(a)))
        end
      }.join('')
      @cache[@cid]=cmd unless /\*/ === @cid
    end
    cmd
  end

  private
  def init_frame
    frames={}
    @doc.find_each('cmdframe','command'){|e0|
      line=e0.to_h
      id=line.delete('id')
      @label[id]=line.delete('label')
      @response[id]=line.delete('response')
      select=[]
      @rep.each(e0){|e1|
        select << init_data(e1)
      }
      frame=[]
      @doc['cmdframe'].each{|e1|
        case e1.name
        when 'data'
          frame << init_data(e1)
        when 'ccrange'
          line['method']=e1['method']
          ccrange=[]
          e1.each{|e2|
            case e2.name
            when 'data'
              ccrange << init_data(e2)
            when 'select'
              ccrange.concat select
            end
          }
          line['ccrange']=ccrange
          frame << :ccrange
        when 'select'
          frame.concat select
        end
      }
      line['frame']=frame
      frames[id] = line
      @v.msg{"Frame:[#{line}]"}
    }
    frames
  end

  def init_data(e)
    attr=e.to_h
    label=attr.delete('label')
    attr['val']=@rep.subst(e.text)
    @v.msg{"InitFrame:#{label}[#{e}]"}
    attr
  end
end
