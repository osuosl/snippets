#!/bin/ruby
p = Project.find 72
fileext = ".json"
dump_dir = "dump"
#p.members.map(&:user_id).map { |author_id| User.find author_id }

#Get all the model names
models = Module.constants.select do |constant_name|
  constant = eval constant_name
  (! constant.nil?) && constant.is_a?(Class) && (constant.superclass == ActiveRecord::Base)
end
models = models.map(&:underscore).map(&:pluralize)


#get all the models associated with the project
models.each do |m|
  model_file = File.join(Rails.root, dump_dir, m + fileext)
  file = File.open(model_file, 'w')
  file << p.send(m).to_json if p.methods.include?(m)
  file.close()
end
#get the project model itself
model_file = File.join(Rails.root, dump_dir,'projects.' + fileext)
file = File.open(model_file, 'w')
file << p.to_json if p.methods.include?(m)
file.close()
