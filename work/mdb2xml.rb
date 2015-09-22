#!/usr/bin/ruby
# IDB CSV(CIAX-v1) to XML
#alias m2x
require 'json'

def indent(str)
  puts '  '*@indent+str
end

def prt_cond(fld)
  @indent+=1
  fld.each{|cond|
    attr='form ="msg"'
    if /:/ =~ cond
      attr+=' site="%s"' % $`
      cond=$'
    end
    if /[!=\~]/ =~ cond
      attr+=' var="%s"' % $`
      tag={'~'=>'pattern','!'=>'not','='=>'equal'}[$&]
      indent('<%s %s>%s</%s>' % [tag,attr,$',tag])
    end
  }
  @indent-=1
end

def prt_exe(cmd)
  indent('<exe site="%s" id="%s"/>' % cmd.split(':'))
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
    indent('<mcr id="%s"/>' % id)
  }
end

abort "Usage: mdb2xml [mdb(json) file]" if STDIN.tty? && ARGV.size < 1

proj=ENV['PROJ']||'moircs'

@mdb=JSON.load(gets(nil))
@indent=0
indent('<?xml version="1.0" encoding="utf-8"?>')
indent('<mdb xmlns="http://ciax.sum.naoj.org/ciax-xml/mdb">')
@indent+=1
indent("<macro id=\"#{proj}\" version=\"1\" label=\"#{proj.upcase} Macro\" port=\"55555\">")
@indent+=1
@mdb.each{|id,db|
  item='<item id="'+id+'"'
  item << ' title="%s"' % db['title'] if db['title']  
  indent(item+'>')
  @indent+=1
  db.each{|key,data|
    case key
    when 'goal'
      indent("<goal>")
      prt_cond(data)
      indent("</goal>")
    when 'check'
      indent("<check>")
      prt_cond(data)
      indent("</check>")
    when 'exe'
      prt_exe(data.first)
    when 'seq'
      prt_seq(data)
    end
  }
  @indent-=1
  indent("</item>")
}
@indent-=1
indent('</macro>')
@indent-=1
indent('</mdb>')
