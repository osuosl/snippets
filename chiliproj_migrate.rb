#!/bin/ruby
p = Project.find 72
$fileext = ".json"
$dump_dir = "dump"
$encoder = "to_json"
#p.members.map(&:user_id).map { |author_id| User.find author_id }

#Get all the model names
models = Module.constants

models.each do |m|
  model_name = p.methods.grep(/^#{m.underscore}$|^#{m.underscore.pluralize}$/)[0]
  if(not model_name.nil? || model_name == "debugger")
    model_file = File.join(Rails.root, $dump_dir, model_name + $fileext)
    file = File.open(model_file, 'w')
    begin
      puts "Goint to call #{model_name} to be encoded as #{$encoder}"
      file << p.send(model_name).send($encoder.to_sym)
      raise if(p.send(model_name).class.name == "Fixnum")
    rescue
      puts "Hey, #{model_name} had a problem!"
      file.close()
      File.delete(model_file)
      next
    end
    file.close()
  end
end


def write_to_file(object)
  begin
    file_name = object.first.class.name.underscore.pluralize + $fileext
  rescue
    puts("Cannot write object to file.")
    return
  end
  file = File.open(File.join(Rails.root, $dump_dir, file_name), 'w')
  file << object.map(&$encoder.to_sym)
  file.close()
end

[
  Role,
  AuthSource,
  AuthSourceLdap,
  CustomField,
  DocumentCategoryCustomField,
  Enumeration,
  GroupCustomField,
  Group,
  IssueStatus,
  IssuePriority,
  IssuePriorityCustomField,
  ProjectCustomField,
  Setting,
  TimeEntryActivityCustomField,
  TimeEntryCustomField,
  UserCustomField,
  VersionCustomField,
  Tracker,
  Workflow
].each { |m| write_to_file(m.all) }

[Journal, Query, Repository, DocumentCategory].each do |proj_id|
  write_to_file(
    proj_id.all.select do |obj|
      obj.project.id == p.id
    end
  )
end

[WikiContent,Comment, Message].each do |m|
  write_to_file(
    m.all.select do |c|
      p.users.map(&:id).include?( c.author_id)
    end
  )
end


write_to_file(
  MemberRole.all.select do |m|
    p.users.map(&:id).include?( m.member_id)
  end
)

[Token, UserPreference, Watcher].each do |m|
  write_to_file(
    m.all.select do |elt|
      p.users.map(&:id).include?(elt.user_id)
    end
  )
end

write_to_file(
  IssueRelation.all.select do |i|
    p.issues.map(&:id).include?(i.issue_to_id) || p.issues.map(&:id).include?(i.issue_from_id)
  end
)

[WikiPage, WikiRedirect].each do |wik|
  write_to_file(
    wik.all.select do |w|
      p.wiki.id == w.wiki_id
    end
  )
end
