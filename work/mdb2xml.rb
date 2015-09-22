#!/usr/bin/ruby
# IDB CSV(CIAX-v1) to XML
#alias m2x
require 'json'

def indent(tag,attr={},text=nil)
  print '  '*@indent+'<'+tag
  attr.each{|k,v|
    print ' '+k+'="'+v+'"'
  }
  if text
    puts ">#{text}</#{tag}>"
  elsif defined?(yield)
    puts '>'
    @indent+=1
    yield
    @indent-=1
    puts '  '*@indent+"</#{tag}>"
  else
    puts '/>'
  end
end

def prt_cond(fld)
  fld.each{|cond|
    attr={'form' => 'msg'}
    if /:/ =~ cond
      attr['site']=$`
      cond=$'
    end
    if /[!=\~]/ =~ cond
      attr['var']=$`
      indent(@tbl[$&],attr,$')
    end
  }
end

def prt_exe(cmd)
  site,id=cmd.split(':')
  indent('exe',{'site'=>site,'id'=>id})
end

def prt_seq(seq)
  seq.each{|cmd|
    site,id=cmd.split(':')
    if site != 'mcr'
      id="#{site}_#{id}"
      if !@mdb.key?(id)
        prt_exe(cmd)
        next
      end
    end
    indent('mcr',{'id'=>id})
  }
end

abort "Usage: mdb2xml [mdb(json) file]" if STDIN.tty? && ARGV.size < 1

proj=ENV['PROJ']||'moircs'

@mdb=JSON.load(gets(nil))
@indent=0
@tbl={'~'=>'pattern','!'=>'not','='=>'equal'}
puts '<?xml version="1.0" encoding="utf-8"?>'
indent('mdb','xmlns'=>'http://ciax.sum.naoj.org/ciax-xml/mdb'){
  indent('macro',{'id'=>proj,'version'=>'1','label'=>"#{proj.upcase} Macro",'port'=>'55555'}){
    @mdb.each{|id,db|
      attr={'id'=>id}
      attr['title']=db['title'] if db['title']
      indent('item',attr){
        db.each{|key,data|
          case key
          when 'goal'
            indent("goal"){
              prt_cond(data)
            }
          when 'check'
            indent("check"){
              prt_cond(data)
            }
          when 'exe'
            prt_exe(data.first)
          when 'seq'
            prt_seq(data)
          end
        }
      }
    }
  }
}
