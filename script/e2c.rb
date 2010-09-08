#!/usr/bin/ruby
require "optparse"
require "rexml/document"
include REXML

abort "Usage: e2c [xpath] [child elem] < xml" if ARGV.size < 2

xpath=ARGV.shift
child=ARGV.shift
doc=Document.new(gets(nil))
doc.each_element(xpath) {|e|
  a=e.attributes
  e.add_element(child,a)
  a.each_attribute { |attr| attr.remove }
}
puts doc
