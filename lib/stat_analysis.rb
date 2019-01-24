def generate_knit(element, csv_files, input_dir)

  if Model.competencies.include?element
    title = "Competency #{element}"
    ymin =  Model.competency_grade_range[0]
    ymax =  Model.competency_grade_range[1]
  elsif Model.learning_outcomes.include?(element)
    title = "Learning Outcome #{element}"
    ymin =  Model.learning_outcome_grade_range[0]
    ymax =  Model.learning_outcome_grade_range[1]
  else
    title = "Assessment Tool #{element}"
    ymin =  Model.assessment_tool_grade_range[0]
    ymax =  Model.assessment_tool_grade_range[1]
  end

  result = <<-ENDSTR
---
title: "Analysis of #{title}"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

```{r includes, include=FALSE}
if("psych" %in% rownames(installed.packages()) == FALSE) {install.packages("psych")}
library(psych)

if("tidyverse" %in% rownames(installed.packages()) == FALSE) {install.packages("tidyverse")}
library(tidyverse)

if("car" %in% rownames(installed.packages()) == FALSE) {install.packages("car")}
library(car)

if("lsr" %in% rownames(installed.packages()) == FALSE) {install.packages("lsr")}
library(lsr)
```

```{r load_data, include=FALSE}
ENDSTR

  courses = Array.new
  csv_files.each do |f|
    f =~ /#{input_dir}\/grades\/(.+?)[.]csv/
    courses << $1
  end

  courses.each do |c|
    result += <<-ENDSTR
data#{c} <- read.csv("#{c}.csv", 
                 header = TRUE, 
                 sep=",",  
                 na = c("", "NA"),
                 strip.white=TRUE)
ENDSTR
  end
  result += "data <- data.frame(\n"
  result += "#{element} = c("
  i = 0
  while i<courses.length
    result += "data#{courses[i]}$#{element}"
    i += 1
    result += ',' if i<courses.length
  end
  result += "),\n"
  result += "Course = factor("
  result += "c("
  i = 0
  while i<courses.length
    result += "rep(\"#{courses[i]}\",nrow(data#{courses[i]}))"
    i += 1
    result += ',' if i<courses.length
  end
  result += "),\n"
  result += "levels=ordered(c("
  i = 0
  while i<courses.length
    result += "\"#{courses[i]}\""
    i += 1
    result += ',' if i<courses.length
  end
  result += "))\n"
  result += ")\n"
  result += ")\n"
  result += <<-ENDSTR
  

```

# 1. Descriptive statistics
```{r boxplot, echo=FALSE}
ggplot(data, aes(x=Course, y=#{element})) +
ENDSTR
  if ymin>0
    result += <<-ENDSTR
  geom_rect(aes(ymin=min(c(data$#{element}),#{ymin}), ymax=#{ymin}, xmin="#{courses[0]}", xmax="#{courses[courses.length-1]}"), 
            fill="red", alpha=0.002) +
ENDSTR
  end
  if ymax != ymin
    result += <<-ENDSTR
  geom_rect(aes(ymin=#{ymin+0.01}, ymax=#{ymax}, xmin="#{courses[0]}", xmax="#{courses[courses.length-1]}"), 
            fill="yellow", alpha=0.01)+
ENDSTR
  end
  if ymin>0
    result += <<-ENDSTR
  geom_rect(aes(ymin=#{ymax+0.01}, ymax=max(c(data$#{element},#{ymax+0.01})), xmin="#{courses[0]}", xmax="#{courses[courses.length-1]}"), 
            fill="green", alpha=0.01)+
ENDSTR
  end
  result += <<-ENDSTR
    geom_boxplot(size=1) +
  scale_y_continuous("#{title}", breaks= 1:7) 
```

```{r descriptive_statistics, echo=FALSE}
describeBy(data$#{element}, data$Course)
```

# 2. Statistical inference: One-way ANOVA 
```{r anova, include=FALSE}
aov.model <- aov(data$#{element} ~ data$Course)
```
## 2.1 ANOVA requirements
### 2.1.1 Do residuals follow a normal distribution?
```{r shapiro, echo=FALSE}
aov.residuals <- residuals(object = aov.model)
shapiro.test(aov.residuals)
```
### 2.1.2 Homogeneity of Variance
```{r levene, echo=FALSE}
leveneTest(data$#{element}, data$Course)
```

## 2.2 ANOVA result
```{r anova_result, echo=FALSE}
summary(aov.model)
```
## 2.3 Effect size
```{r eta, echo=FALSE}
etaSquared(aov.model, anova=T)
```
## 2.4 Post hoc tests
```{r tukey, echo=FALSE}
TukeyHSD(aov.model)
```
ENDSTR

  result

end