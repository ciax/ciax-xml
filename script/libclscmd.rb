#!/usr/bin/ruby
require "libparam"
require "librepeat"
require "libverbose"

class ClsCmd
  attr_reader :par,:label

  def initialize(doc)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @v=Verbose.new("doc/#{doc['id']}/cmd".upcase)
    @par=Param.new
    @label={}
    @session={}
    init_cmd(doc)
  end

  def setcmd(ssn)
    @id=ssn.first
    @sel=@session[ssn.first] || list_cmd
    @par.setpar(ssn)
    self
  end

  def statements
    @v.msg{"Exec(CDB):#{@id}"}
    stma=[]
    @sel.each{|e1|
      stm=[]
      @v.msg(1){"GetCmd(DDB):#{e1.first}"}
      begin
        e1.each{|e2| # //argv
          case e2
          when String
            stm << e2
          when Hash
            str=@par.subst(e2['val'])
            str=e2['format'] % eval(str) if e2['format']
            @v.msg{"Calculated [#{str}]"}
            stm << str
          end
        }
        stma << stm
      ensure
        @v.msg(-1){"Exec(DDB):#{stm}"}
      end
    }
    stma
  end

  private
  def init_cmd(doc)
    rep=Repeat.new
    doc['commands'].each{|e0|
      id=e0['id']
      @label[id]=e0['label']
      @session[id]=[]
      rep.each(e0){|e1|
        case e1.name
        when 'statement'
          command=[e1['command']]
          e1.each{|e2|
            argv=e2.to_h
            argv['val'] = rep.subst(e2.text)
            command << argv.freeze
          }
          @session[id] << command.freeze
        when 'parameters'
          @par[id]=[]
           e1.each{|e2|
            param=e2.to_h
            param['val']=e2.text
            @par[id] << param.freeze
          @v.msg{"Parameters:Init[#{id}] #{@par[id]}"}
          }
        end
      }
      @v.msg{"Session:Init[#{id}] #{@session[id]}"}
    }
    self
  end

  def list_cmd
    err=["== Command List=="]
    @label.each{|key,val|
      err << (" %-10s: %s" % [key,val]) if val
    }
    raise SelectID,err.join("\n")
  end
end
