#!/usr/bin/ruby
require "optparse"
require "xml"
include XML

if ARGV.size < 2
  abort <<EOF
Usage: a2t (-r) [xpath] [attr] < xml
       //xpath@attr <-> //xpath.text()
EOF
end
opt= ARGV[0] == '-r' ? ARGV.shift : nil
xpath=ARGV.shift
attr=ARGV.shift || abort("No attr")
doc=Document.io(STDIN)
ns=doc.root.namespaces.namespace.to_s
  doc.find("//ns:#{xpath}","ns:#{ns}").each {|e|
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
