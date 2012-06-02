require 'pp'
require 'pathname'

# Use MzScheme for parsing now (should probably test it with 
scheme_parse = Pathname.new("#{RAILS_ROOT}/vendor/scheme_parse.ss").realpath
scheme_print = Pathname.new("#{RAILS_ROOT}/vendor/scheme_print.ss").realpath

$parse_cmd = "cd %s && mzscheme -r #{scheme_parse}"
$print_cmd = "petite --script #{scheme_print}"

# Comper and Checker commands have been moved to /vendor/libcheck/lang/*/init.rb
