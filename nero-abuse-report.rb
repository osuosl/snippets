#!/opt/chefdk/embedded/bin/ruby
require 'json'
require 'trello'

Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_PUBLIC_KEY']
  config.member_token = ENV['TRELLO_MEMBER_TOKEN']
end

email_file = File.read(ARGV[0])
# Data string we need to grab out of the email
DATA_REGEX = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+\|\s+([0-9\-:\s]+)\s+\|\s+(\{.+\})/
# Some of the JSON is split up into multiple lines, this cleans it up
CLEANUP_REGEX = /({[^}\n]+)\n\s([^}\n]+)\n\s([^}\n]+})/
reports = []
types = {}
hosts = {}
reports[0] = ''
inc = 0
# Find each report type
email_file.each_line do |line|
  next unless line =~ /^Report:/..line =~ /^---$/
  reports[inc] = reports[inc].concat(line)
  if line =~ /^---/
    inc += 1
    reports[inc] = ''
  end
end

# For each report, create a hash with the data we want
reports.each do |report|
  report.gsub!(CLEANUP_REGEX, '\1\2\3')
  type = report.match(/Report: (\w+)/)[1]
  type_desc = report.match(/(?:Report:\s[\w-]+\n*.*?[\n\r]+)(.*?)(?>\s+IP)/m)[1]
  types[type] = type_desc
  report.each_line do |line|
    # Skip if the data is not what we want
    next unless line.match(DATA_REGEX)
    ip = line.match(DATA_REGEX)[1]
    timestamp = line.match(DATA_REGEX)[2]
    # Remove extra newlines which show up as xD codes
    json_data = JSON.parse(line.match(DATA_REGEX)[3].delete("\r"))
    tag = json_data['tag']
    hostname = json_data['hostname']
    # Strip data we don't need
    json_data.tap do |data|
      %w(sector city region geo asn sic tag hostname).each do |k|
        data.delete(k)
      end
    end

    # Add the record into a hash
    if hosts.include?(ip)
      hosts[ip]['types'][type] = {
        timestamp: timestamp,
        tag: tag,
        data: json_data
      }
    else
      hosts.merge!(ip => {
                     hostname: hostname,
                     'types' => {
                       type => {
                         timestamp: timestamp,
                         tag: tag,
                         data: json_data
                       }
                     }
                   })
    end
  end
end
# puts JSON.pretty_generate(hosts)
# exit

board = Trello::Board.find('Txq3hmlF')

reported_list = nil
contacted_list = nil
type_list = nil
board.lists.each do |list|
  reported_list = list if list.name =~ /Reported/
  contacted_list = list if list.name =~ /Contacted/
  type_list = list if list.name =~ /Report Types/
end

current_labels = {}
board.labels.each do |label|
  current_labels[label.name] = label.id
  label.delete if label.name.empty?
end

type_cards = {}
type_list.cards.each do |card|
  type_cards.merge!(card.name => card.id)
end

types.each do |type, _type_desc|
  unless current_labels.include?(type)
    Trello::Label.create(
      name: type,
      board_id: board.id
    )
  end
  next if type_cards.include?(type)
  Trello::Card.create(
    name: type,
    list_id: type_list.id,
    desc: types[type]
  )
end

reported_cards = {}
reported_list.cards.each do |card|
  reported_cards.merge!(card.name => card.id)
end

contacted_cards = {}
contacted_list.cards.each do |card|
  contacted_cards.merge!(card.name => card.id)
end

hosts.each do |host, data|
  name = "#{host} (#{data[:hostname]})"
  description = ''
  labels = []
  data['types'].each do |type, data|
    data_desc = ''
    labels << current_labels[type]
    data[:data].each do |key, value|
      data_desc.concat("#{key}: #{value}\n")
    end
    description.concat("#{type}\n#{'-' * type.length}\n\n#{data[:timestamp]}\n\n```\n#{data_desc}\n```\n\n")
  end

  if contacted_cards.include?(name)
    card = Trello::Card.find(contacted_cards[name])
    card.name = name
    card.desc = description + "\n\n" + card.desc
    card.card_labels = labels
    card.closed = false
    puts 'Updating Contacted card ' + card.name
    card.save
  elsif reported_cards.include?(name)
    card = Trello::Card.find(reported_cards[name])
    card.name = name
    card.desc = description + "\n\n" + card.desc
    card.card_labels = labels
    card.closed = false
    puts 'Updating Reported card ' + card.name
    card.save
  else
    puts 'Creating new card ' + name
    Trello::Card.create(
      name: name,
      list_id: reported_list.id,
      card_labels: labels,
      desc: description
    )
  end
end
