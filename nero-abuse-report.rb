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
types = []
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
  types << type
  report.each_line do |line|
    # Skip if the data is not what we want
    next unless line.match(DATA_REGEX)
    ip = line.match(DATA_REGEX)[1]
    timestamp = line.match(DATA_REGEX)[2]
    # Remove extra newlines which show up as xD codes
    json_data = JSON.parse(line.match(DATA_REGEX)[3].gsub(/\u000D/, ''))
    tag = json_data['tag']
    hostname = json_data['hostname']
    # Strip data we don't need
    json_data.tap do |data|
      %w(sector city region geo asn sic tag hostname).each do |k|
        data.delete(k)
      end
    end

    # Add the record into a hash
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
puts JSON.pretty_generate(hosts)
exit

board = Trello::Board.find('Txq3hmlF')

reported_list = nil
board.lists.each do |list|
  reported_list = list if list.name =~ /Reported/
end

current_labels = {}
board.labels.each do |label|
  current_labels[label.name] = label.id
  label.delete if label.name.empty?
end

types.each do |type|
  next if current_labels.include?(type)
  Trello::Label.create(
    name: type,
    board_id: board.id
  )
end

cards = {}
reported_list.cards.each do |card|
  cards.merge!(card.name => card.id)
end

hosts.each do |host, data|
  name = "#{host} (#{data[:hostname]})"
  description = ''
  types = ''
  data['types'].each do |type, data|
    data_desc = ''
    types = type
    data[:data].each do |key, value|
      data_desc.concat("#{key}: #{value}\n")
    end
    description = "#{type}\n#{'-' * type.length}\n\n#{data[:timestamp]}\n\n```\n#{data_desc}\n```\n"
  end

  if cards.include?(name)
    card = Trello::Card.find(cards[name])
    card.name = name
    card.desc = description
    card.card_labels = current_labels[types]
    puts 'Updating card ' + card.name
    card.save
  else
    puts 'Creating new card ' + name
    Trello::Card.create(
      name: name,
      list_id: reported_list.id,
      card_labels: current_labels[types],
      desc: description
    )
  end
end
