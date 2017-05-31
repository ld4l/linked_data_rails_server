# What did you ask for?
class UserInputError < StandardError
end

USAGE_TEXT = 'Usage: ld4l_run_link_data_server <target_dir> <report_file> <uri_prefix> [REPLACE]'

def process_arguments(args)
  replace_report = args.delete('REPLACE')

  raise UserInputError.new(USAGE_TEXT) unless args && args.size == 3

  files_base = File.expand_path(args[0])
  raise UserInputError.new("Target directory doesn't exist: #{files_base}") unless Dir.exist?(files_base)

  raise UserInputError.new("#{args[1]} already exists -- specify REPLACE") if File.exist?(args[1]) unless replace_report
  raise UserInputError.new("Can't create #{args[1]}: no parent directory.") unless Dir.exist?(File.dirname(args[1]))

  $files = Ld4lBrowserData::Utilities::FileSystems::MySqlZipFS.new(:username => 'ld4luser', :password => 'ld4lpass')
  $report = File.open(File.expand_path(args[1]), 'w')
end

begin
process_arguments(ARGV)
rescue UserInputError
  puts
  puts "ERROR: #{$!}"
  puts
  exit
end

