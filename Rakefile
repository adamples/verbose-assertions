require 'yard'
require 'yard/rake/yardoc_task'
require 'fileutils'

DOC_FILES = [
  "example.rb",
  "lib/test/verbose_unit/test_case.rb",
  "lib/test/verbose_unit/assertions.rb",
  "lib/test/verbose_unit/assertion_failed_error.rb",
  "test/test_assertions.rb"
]


task :default => [:all]

task :all => [:readme, :doc]
task :clean => [:clean_readme, :clean_doc]


# - README ------------------------------------------------------------------- #

task :readme do
  File.open("README", "w") do |o|
    o.puts "= VerboseAssertions"

    DOC_FILES.each do |path|
      o.puts
      o.puts "== #{path}"
      o.puts

      File.open(path, "r") do |i|
        while !i.eof?
          o.print "    #{i.readline}"
        end
      end
    end
  end
end

task :clean_readme do
  File.delete("README") if File.file?("README")
end

# - end of README ------------------------------------------------------------ #

# - Documentation ------------------------------------------------------------ #

task :doc => [:yard]

YARD::Rake::YardocTask.new do |t|
  t.files   = ['**/*.rb']
end

task :clean_doc do
  FileUtils.rm_rf("doc") if File.directory?("doc")
end

# - end of Documentation ----------------------------------------------------- #
