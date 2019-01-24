def competency(*args)
  args.each do |c|
    Model.elements[c] = Element.new(:C)
    Model.competencies << c
  end
end

def learning_outcome(*args)
  args.each do |lo|
    Model.elements[lo] = Element.new(:LO)
    Model.learning_outcomes << lo
  end
end

def assessment_tool(*args)
  args.each do |at|
    Model.elements[at] = Element.new(:AT)
    Model.assessment_tools << at
  end
end

def grade_range(*args)
  Model.competency_grade_range = args
  Model.learning_outcome_grade_range = args
  Model.assessment_tool_grade_range = args
end

def competency_grade_range(*args)
  Model.competency_grade_range = args
end

def learning_outcome_grade_range(*args)
  Model.learning_outcome_grade_range = args
end

def assessment_tool_grade_range(*args)
  Model.assessment_tool_grade_range = args
end


def weight(element, descendant, weight)
  # Possible errors
  if !Model.elements.has_key?(element)
    puts "<< ERROR >> Before using #{element} in a decomposition, it needs to be defined with one of the following keywords: competency, learning_outcome, or assessment_tool"
    exit
  end
  if !Model.elements.has_key?(descendant)
    puts "<< ERROR >> Before using #{descendant} in a decomposition, it needs to be defined with one of the following keywords: competency, learning_outcome, or assessment_tool"
    exit
  end

  # Do the job
  Model.elements[element].descendants[descendant] = weight
end


def parse_competency_model(str)
  competency_model = File.read(str)

  # replace decompose code with weight code; for instance:
  #
  # decompose "C1" into
  # "LO1" weights 0.25
  # "C2" weights 0.25
  # "C3" weights 0.5
  # end
  #
  # is replaced by
  # weight(C1, LO1, 0.25)
  # weight(C1, C2, 0.25)
  # weight(C1, C3, 0.5)

  dempositions = competency_model.scan(/decompose\s+".+?"\s+\binto\b.+?\bend\b/m)
  dempositions.each do |dec|
    dec =~ /decompose\s+"(.+?)"/
    composite = $1
    weights = dec.scan(/".+?"\s+weights\s+\d[.]?\d*/)
    new_dec_code = ''
    weights.each do |w|
      w =~ /"(.+?)"\s+weights\s+(\d[.]?\d*)/
      descendant = $1
      new_dec_code += "weight(\"#{composite}\", \"#{$1}\", #{$2})\n"
    end
    competency_model.gsub!(Regexp.new(dec), new_dec_code)
  end
  eval competency_model
  Model.get_roots
end
