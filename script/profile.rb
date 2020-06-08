require 'ruby-prof'
require_relative '../lib/wheretz'

RubyProf.start
WhereTZ.lookup(50.004444, 36.231389)
result = RubyProf.stop
RubyProf::GraphHtmlPrinter.new(result).print(File.open('tmp/prof.html', 'w'))
