#!/usr/bin/ruby
# IDB CSV(CIAX-v1) to XML
#alias m2x
require 'json'

def prt_cond(fld)
  fld.each{|cond|
    attr='form ="msg"'
    if /:/ =~ cond
      attr+=' site="%s"' % $`
      cond=$'
    end
    if /[!=\~]/ =~ cond
      attr+=' var="%s"' % $`
      tag={'~'=>'pattern','!'=>'not','='=>'equal'}[$&]
      puts '   <%s %s>%s</%s>' % [tag,attr,$',tag]
    end
  }
end

def prt_exe(cmd)
  puts '  <exe site="%s" id="%s"/>' % cmd.split(':')
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
    puts '  <mcr id="%s"/>' % id
  }
end

abort "Usage: mdb2xml [mdb(json) file]" if STDIN.tty? && ARGV.size < 1

@mdb=JSON.load(gets(nil))
@mdb.each{|id,db|
  print '<item id="'+id+'"'
  print ' title="%s"' % db['title'] if db['title']  
  puts '>'
  db.each{|key,data|
    case key
    when 'goal'
      puts "  <goal>"
      prt_cond(data)
      puts "  </goal>"
    when 'check'
      puts "  <check>"
      prt_cond(data)
      puts "  </check>"
    when 'exe'
      prt_exe(data.first)
    when 'seq'
      prt_seq(data)
    end
  }
  puts "</item>"
}
