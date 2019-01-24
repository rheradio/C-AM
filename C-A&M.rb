require_relative './lib/metamodel.rb'
require_relative './lib/metamodel_parser.rb'
require_relative './lib/stat_analysis.rb'
require_relative './lib/check_input_data.rb'
require 'pathname'
require 'fileutils'

# Check command line parameters
if ARGV.length != 2
  puts "<< ERROR >> ruby CompEval.rb input_dir output_dir"
  exit
else
  input_dir = ARGV[0]
  output_dir = ARGV[1]
  if !Pathname.new("#{input_dir}/competency_model.txt").exist?
    puts "<< ERROR >> The directory \"#{input_dir}\" should include a file named \"competency_model.txt\""
    exit
  end
  if Dir["#{input_dir}/grades/*.csv"].length == 0
    puts "<< ERROR >> The directory \"#{input_dir}\" should include a subfolder \"grades\" with the csv files of the students' grades (check the examples directory)"
    exit
  end
end

# Create an empty output dir
FileUtils.rm_rf(output_dir)
Dir.mkdir(output_dir)
Dir.mkdir("#{output_dir}/students")
Dir.mkdir("#{output_dir}/instructors")

parse_competency_model("#{input_dir}/competency_model.txt")
check_competency_model

GraphViz.parse_string(Model.to_dot).output(:pdf=> "#{output_dir}/competency_model.pdf")
output_csv_head = "#{Model.competencies.join(',')},#{Model.learning_outcomes.join(',')},#{Model.assessment_tools.join(',')}\n"

csv_files = Dir["#{input_dir}/grades/*.csv"]
csv_files.each do |f|
  file = File.open(f).read
  output_csv_code = output_csv_head
  puts "\nComputing grades for #{f}\n"
  f =~ /#{input_dir}\/grades\/(.+?)[.]csv/
  file_name = $1
  Dir.mkdir("#{output_dir}/students/#{file_name}")
  head = file.lines[0].split(/,/)
  i = 1
  while i<file.lines.length
    print "#" if i%10==0
    grades = Hash.new
    row = file.lines[i].split(/,/)
    student_id = nil
    j = 0
    while j<row.length
      if head[j].strip == "student_id"
        student_id = row[j].strip
      else
        grades[head[j].strip] = row[j].strip.to_f
      end
      j += 1
    end
    all_ATs_in_csv(grades)
    Model.get_grades(grades)
    Model.competencies.each {|c| output_csv_code += "#{grades[c].round(2)},"}
    Model.learning_outcomes.each {|lo| output_csv_code += "#{grades[lo].round(2)},"}
    Model.assessment_tools.each {|at| output_csv_code += "#{grades[at].round(2)},"}
    output_csv_code.sub!(/,$/, "\n")
    GraphViz.parse_string(Model.to_dot(grades)).output(:pdf=> "#{output_dir}/students/#{file_name}/#{student_id}.pdf")
    i += 1
  end
  File.open("#{output_dir}/instructors/#{file_name}.csv", 'w+').write(output_csv_code)
end

elements = Model.competencies + Model.learning_outcomes + Model.assessment_tools
elements.each do |e|
  knit_code = generate_knit(e, csv_files, input_dir)
  File.open("#{output_dir}/instructors/#{e}.Rmd", 'w+').write(knit_code)
end


