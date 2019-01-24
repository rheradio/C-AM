def ensure_ranges

  if Model.competency_grade_range.empty?
    puts "<< WARNING >>: no range for competency grades has been specified (it's [0,0] by default)"
    Model.competency_grade_range = [0,0]
  elsif Model.competency_grade_range.length < 2
    puts "<< WARNING >>: the range for competency grades doesn't include 2 numbers"
    Model.competency_grade_range = [Model.competency_grade_range[0],Model.competency_grade_range[0]]
  end

  if Model.learning_outcome_grade_range.empty?
    puts "<< WARNING >>: no range for learning outcome grades has been specified (it's [0,0] by default)"
    Model.learning_outcome_grade_range = [0,0]
  elsif Model.learning_outcome_grade_range.length < 2
    puts "<< WARNING >>: the range for learning outcome grades doesn't include 2 numbers"
    Model.learning_outcome_grade_range = [Model.learning_outcome_grade_range[0],Model.learning_outcome_grade_range[0]]
  end

  if Model.assessment_tool_grade_range.empty?
    puts "<< WARNING >>: no range for assessment tool grades has been specified (it's [0,0] by default)"
    Model.assessment_tool_grade_range = [0,0]
  elsif Model.assessment_tool_grade_range.length < 2
    puts "<< WARNING >>: the range for assessment tool grades doesn't include 2 numbers"
    Model.assessment_tool_grade_range = [Model.assessment_tool_grade_range[0],Model.assessment_tool_grade_range[0]]
  end

end

#All weights add up to 1
def ensure_weights
  Model.elements.each do |name, e|
    if !e.descendants.empty?
      weight = 0
      e.descendants.each do |key, value|
        weight += value.to_f
      end
      if weight != 1
        puts "<< ERROR >> The descendant weights of #{name} don't add up to 1"
        exit
      end
    end
  end

end

def check_competency_model
  ensure_ranges
  ensure_weights
end

def all_ATs_in_csv(grades)
  Model.assessment_tools.each do |at|
    if grades[at].nil?
      puts "<< ERROR >> Some of the input csv files are not providing values to Assessment Tool #{at} (i.e., a column named #{at} is missing)"
      exit
    end
  end

end
