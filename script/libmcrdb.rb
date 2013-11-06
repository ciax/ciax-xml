#!/usr/bin/ruby
require "librepeat"
require "libdb"

module CIAX
  module Mcr
    class Db < Db
      def initialize
        super('mdb')
      end

      private
      def doc_to_db(doc)
        hash=Hash[doc]
        hcmd=hash[:command]={}
        hcmd[:index]=init_command(doc.top)
        hash
      end

      def init_command(mdbc)
        hash={}
        mdbc.each{|e0|
          verbose("Mdb","MACRO:[#{e0['id']}]")
          id=e0.attr2item(hash)
          item=hash[id]
          body=(item[:body]||=[])
          final={}
          e0.each{|e1,rep|
            attr=e1.to_h
            par2item(e1,item) && next
            attr['type'] = e1.name
            case e1.name
            when 'check','wait'
              body << mkcond(e1,attr)
            when 'goal'
              body << mkcond(e1,attr)
              final.update(attr)['type'] = 'check'
            when 'exec'
              attr['args']=getcmd(e1)
              attr.delete('name')
              body << attr
              verbose("Mdb","COMMAND:[#{e1['name']}]")
            when 'mcr'
              args=attr['args']=getcmd(e1)
              attr['label']=hash[args.first][:label]
              attr.delete('name')
              body << attr
            end
          }
          body << final unless final.empty?
        }
        hash
      end

      def mkcond(e1,attr)
        e1.each{|e2|
          (attr['stat']||=[]) << e2.to_h
        }
        attr
      end

      def getcmd(e1)
        args=[e1['name']]
        e1.each{|e2|
          args << e2.text
        }
        args
      end
    end
  end

  if __FILE__ == $0
    begin
      mdb=Mcr::Db.new.set(ARGV.shift)
    rescue InvalidID
      Msg.usage "[id] (key) .."
      Msg.exit
    end
    puts mdb.path(ARGV)
  end
end
