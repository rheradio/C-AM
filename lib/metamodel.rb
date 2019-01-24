require 'ruby-graphviz'
# https://github.com/glejeune/Ruby-Graphviz
# Add C:\Program Files (x86)\Graphviz2.38\bin to the path (env. variables)

class Element
  attr_accessor :type, :descendants, :mark, :grade
  def initialize(type)
    @type = type # :C, :LO, :AT
    @descendants = Hash.new
    @mark = false
  end
  def to_s
    result = "type: #{type}\n"
    if !descendants.empty?
      result += "descendants:\n"
      @descendants.each do |key, value|
        result += "\t#{key} weights #{value}\n"
      end
    end
    result
  end
end

class Model # A singleton object
  @elements = Hash.new
  @roots = Array.new
  @competencies = Array.new
  @learning_outcomes = Array.new
  @assessment_tools = Array.new
  @competency_grade_range = Array.new
  @learning_outcome_grade_range = Array.new
  @assessment_tool_grade_range = Array.new

  class << self
    attr_accessor :elements, :roots, :competencies, :learning_outcomes, :assessment_tools
    attr_accessor :competency_grade_range, :learning_outcome_grade_range, :assessment_tool_grade_range

    def to_s
      result = "=================================================\n"
      result += "= Competency model\n"
      result += "=================================================\n"
      result += "Model roots:\n"
      @roots.each do |r|
        result += "\t#{r}\n"
      end
      result += "--------------------------------------\n"
      @elements.each do |key, value|
        result += "name: #{key}\n"
        result += value.to_s
        result += "--------------------------------------\n"
      end
      result
    end

    def to_dot(grades=nil)
      result = "digraph G {\n"
      @competencies.each do |c|
        result += "\t#{c} [shape=box"
        if !grades.nil?
          result += ", label=\"#{c} = #{grades[c].round(2)}\""
          if grades[c] < @competency_grade_range[0]
            result += ",color=coral,style=filled"
          elsif grades[c] < @competency_grade_range[1]
            result += ",color=lightgoldenrod,style=filled"
          else
            result += ",color=palegreen,style=filled"
          end
        end
        result +="];\n"
      end
      @learning_outcomes.each do |lo|
        result += "\t#{lo} [shape=house"
        if !grades.nil?
          result += ", label=\"#{lo} = #{grades[lo].round(2)}\""
          if grades[lo] < @learning_outcome_grade_range[0]
            result += ",color=coral,style=filled"
          elsif grades[lo] < @learning_outcome_grade_range[1]
            result += ",color=lightgoldenrod,style=filled"
          else
            result += ",color=palegreen,style=filled"
          end
        end
        #result += ",color=lightblue,style=filled"
        result +="];\n"
      end
      @assessment_tools.each do |at|
        result += "\t#{at} [shape=ellipse"
        if !grades.nil?
          result += ", label=\"#{at} = #{grades[at].round(2)}\""
          if grades[at] < @assessment_tool_grade_range[0]
            result += ",color=coral,style=filled"
          elsif grades[at] < @assessment_tool_grade_range[1]
            result += ",color=lightgoldenrod,style=filled"
          else
            result += ",color=palegreen,style=filled"
          end
        end
        #result += ",color=lightblue,style=filled"
        result +="];\n"
      end
      @elements.each do |key, value|
        value.descendants.each do |desc, weight|
          result += "\t#{key}->#{desc} [label=\"#{weight}\", dir=none];\n"
        end
      end
      result +='}'
      result
    end

    def get_roots
      competencies_hash = Hash.new
      @competencies.each do |c|
        competencies_hash[c] = true
      end
      @competencies.each do |c|
        Model.elements[c].descendants.each_key do |d|
            competencies_hash[d] = false if Model.elements[d].type == :C
        end
      end
      competencies_hash.each do |key, value|
        @roots << key if value
      end
    end

    def get_grades(grades)
      def get_grades_aux(node_name, grades)
        node = @elements[node_name]
        node.mark = !node.mark
        if node.type != :AT
          grades[node_name] = 0
          node.descendants.each do |desc|
            desc_name = desc[0]
            desc_weight = desc[1]
            if node.mark != @elements[desc_name].mark
              get_grades_aux(desc_name, grades)
            end
            grades[node_name] += desc_weight*grades[desc_name]
          end
        end
      end
      @roots.each {|r| get_grades_aux(r, grades)}
      return grades
    end

  end
end

