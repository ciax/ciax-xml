#!/usr/bin/ruby
# IDB CSV(CIAX-v1) to XML
#alias m2x
require 'json'

def mktag(tag,attr)
  print '  '*@indent+'<'+tag
  attr.each{|k,v|
    print ' '+k+'="'+v+'"'
  }
end

def indent(tag,attr={},text=nil)
  mktag(tag,attr)
  if text
    puts ">#{text}</#{tag}>"
  else
    puts '/>'
  end
end

def enclose(tag,attr={})
  mktag(tag,attr)
  puts '>'
  @indent+=1
  yield
  @indent-=1
  puts '  '*@indent+"</#{tag}>"
end

def prt_cond(fld)
  fld.each{|ary|
    attr={'form' => 'msg'}
    attr['site']=ary[0]
    cond=ary[1]
    if /[!=\~]/ =~ cond
      attr['var']=$`
      indent(@tbl[$&],attr,$')
    end
  }
end

def prt_exe(ary)
  indent('exec',{'site'=>ary[0],'name'=>ary[1]})
end

def prt_seq(seq)
  seq.each{|ary|
    if ary[0] != 'mcr'
      name="#{ary[0]}_#{ary[1]}"
      if !@mdb.key?(name)
        prt_exe(ary)
        next
      end
    else
      name=ary[1]
    end
    indent('mcr',{'name'=>name})
  }
end

abort "Usage: mdb2xml [mdb(json) file]" if STDIN.tty? && ARGV.size < 1

proj=ENV['PROJ']||'moircs'

@mdb=JSON.load(gets(nil))
@indent=0
@tbl={'~'=>'pattern','!'=>'not','='=>'equal'}
puts '<?xml version="1.0" encoding="utf-8"?>'
enclose('mdb','xmlns'=>'http://ciax.sum.naoj.org/ciax-xml/mdb'){
  enclose('macro',{'id'=>proj,'version'=>'1','label'=>"#{proj.upcase} Macro",'port'=>'55555'}){
    @mdb.each{|grp,mem|
      enclose('group',{'id'=>grp}){
        mem.each{|id,db|
          attr={'id'=>id}
          attr['label']=db['label'] if db['label']
          enclose('item',attr){
            db.each{|key,ary|
              case key
              when 'goal'
                enclose("goal"){
                  prt_cond(ary)
                }
              when 'check'
                enclose("check"){
                  prt_cond(ary)
                }
              when 'exec'
                prt_exe(ary.first)
              when 'seq'
                prt_seq(ary)
              when 'wait'
                if ary['sleep']
                  indent("wait",{'sleep'=>ary['sleep']})
                else
                  enclose("wait",{'retry'=>ary['retry']}){
                    prt_cond(ary['until'])
                  }
                end
              end
            }
          }
        }
      }
    }
  }
}
