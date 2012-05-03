#!/usr/bin/ruby
require "libcircular"
require "librepeat"
require "libdb"

class McrDb < Db
  def initialize(id)
    super('mdb')
    set(id){|doc|
      hash={}
      hash.update(doc)
      mdb=(hash[:macro]||={})
      doc.top.each{|e0|
        id=e0.attr2db(mdb)
        @v.msg{"MACRO:[#{id}]"}
        select=((mdb[:select]||={})[id]||=[])
        final={}
        e0.each{|e1,rep|
          attr=e1.to_h
          case e1.name
          when 'par'
            ((mdb[:parameter]||={})[id]||=[]) << e1.text
          when 'check','wait'
            attr['type'] = e1.name
            select << mkcond(e1,attr)
          when 'goal'
            attr['type'] = 'break'
            select << mkcond(e1,attr)
            final.update(attr)['type'] = 'check'
          when 'mcr','exec'
            attr['type'] = e1.name
            attr['cmd']=getcmd(e1)
            attr.delete('name')
            select << attr
            @v.msg{"COMMAND:[#{e1['name']}]"}
          end
        }
        select << final unless final.empty?
      }
      hash
    }
  end

  private
  def mkcond(e1,attr)
    e1.each{|e2|
      (attr['stat']||=[]) << e2.to_h
    }
    attr
  end

  def getcmd(e1)
    cmd=[e1['name']]
    e1.each{|e2|
      cmd << e2.text
    }
    cmd
  end
end

if __FILE__ == $0
  begin
    mdb=McrDb.new(ARGV.shift)
  rescue SelectID
    warn "USAGE: #{$0} [id] (key) .."
    Msg.exit
  end
  puts mdb.path(ARGV)
end

