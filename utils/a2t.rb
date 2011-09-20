#!/usr/bin/ruby
require "optparse"
require "xml"
include XML

if ARGV.size < 3
  abort <<EOF
Usage: a2t (-r) [xpath] [attr] (ns) < xml
       //(xpath)@(attr) <-> //xpath.text()
       http://ciax.sum.naoj.org/ciax-xml/(ns)
EOF
end
opt= ARGV[0] == '-r' ? ARGV.shift : nil
xpath=ARGV.shift
attr=ARGV.shift || abort("No attr")
doc=Document.io(STDIN)
if ns=ARGV.shift
  url="http://ciax.sum.naoj.org/ciax-xml"
  nodes=doc.find("//dns:#{xpath}","dns:#{url}/#{ns}")
else
  nodes=doc.find("//#{xpath}")
end

nodes.each {|e|
  if opt == '-r'
    e[attr]=e.content
    e.content=''
  else
    str=e[attr] || next
    e.content=str
    e.attributes.get_attribute(attr).remove!
  end
}
puts doc
