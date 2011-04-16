#!/usr/bin/ruby
require "libparam"
require "librepeat"
require "libverbose"

class ClsCmd
  attr_reader :par

  def initialize(doc)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @v=Verbose.new("doc/#{doc['id']}/cmd".upcase)
    @par=Param.new
    @session=init_cmd(doc)
  end

  def setcmd(ssn)
    @sel=@session[ssn.first] || list_cmd
    @par.setpar(@sel,ssn)
    self
  end

  def statements
    @v.msg{"Exec(CDB):#{@sel['label']}"}
    stma=[]
    @sel['statements'].each{|e1|
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
    session={}
    rep=Repeat.new
    doc['commands'].each{|e0|
      id=e0['id']
      session[id]={'label'=>e0['label'],'statements'=>[]}
      rep.each(e0){|e1|
        case e1.name
        when 'statement'
          command=[e1['command']]
          e1.each{|e2|
            argv=e2.to_h
            argv['val'] = rep.subst(e2.text)
            command << argv.freeze
          }
          session[id]['statements'] << command.freeze
        when 'parameters'
          session[id][e1.name]=[]
           e1.each{|e2|
            param=e2.to_h
            param['val']=e2.text
            session[id][e1.name] << param.freeze
          }
        end
      }
      @v.msg{"Session:Init[#{id}] #{session[id]}"}
    }
    session.freeze
  end

  def list_cmd
    err=["== Command List=="]
    @session.each{|key,val|
      err << (" %-10s: %s" % [key,val['label']]) if val['label']
    }
    raise SelectID,err.join("\n")
  end
end
