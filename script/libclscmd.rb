#!/usr/bin/ruby
require "libparam"
require "librepeat"
require "libverbose"

class ClsCmd
  attr_reader :par,:label

  def initialize(doc)
    raise "Init Param must be XmlDoc" unless XmlDoc === doc
    @v=Verbose.new("#{doc['id']}/stm",2)
    @par=Param.new(init_cmd(doc))
  end

  def setcmd(ssn)
    @id=ssn.first
    @par.setpar(ssn)
    self
  end

  def statements
    @v.msg{"Exec(CDB):#{@id}"}
    stma=[]
    @par[:statements].each{|e1|
      stm=[]
      @v.msg(1){"GetCmd(DDB):#{e1.first}"}
      begin
        e1.each{|e2| # //argv
          case e2
          when String
            stm << e2
          when Hash
            str=@par.subst(e2['val'],e2['range'])
            str = e2['format'] % eval(str) if e2['format']
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
    session={}
    doc['commands'].each{|e0|
      hash=e0.to_h
      id=hash.delete('id')
      hash[:statements]=[]
      rep.each(e0){|e1|
        command=[e1['command']]
        e1.each{|e2|
          argv=e2.to_h
          argv['val'] = rep.subst(e2.text)
          command << argv.freeze
        }
        hash[:statements] << command.freeze
      }
      session[id]=hash.freeze
      @v.msg{"Session:Init[#{id}] #{hash}"}
    }
    session
  end
end
