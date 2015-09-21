#!/usr/bin/ruby
# IDB CSV(CIAX-v1) to XML
#alias c2xi

def prt_cond(fld)
  fld.split('&').each{|cond|
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

abort "Usage: csv2xml-idb [idb(csv) file]" if STDIN.tty? && ARGV.size < 1

readlines.each{|line|
  next if /^(#.*|)$/ =~ line
  id,goal,chk=line.chomp.split(',')
p line
  puts '<item id="'+id+'">'
  if goal and !goal.empty?
    puts "  <goal>"
    prt_cond(goal)
    puts "  </goal>"
  end
  if chk and !chk.empty?
    puts "  <check>"
    prt_cond(chk)
    puts "  </check>"
  end
  puts "</item>"
}
