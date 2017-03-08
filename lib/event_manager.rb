require 'csv'
require 'sunlight/congress'
require 'erb'
require 'date'

Sunlight::Congress.api_key = 'e179a6973728c4dd3fb1204283aaccb5'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def format_phone_number(phone_number)
  phone_number.insert(3, '-')
  phone_number.insert(7, '-')
  phone_number
end

def validate_phone_number(phone_number)
  cleaned_number = phone_number.scan(/(\d+)/).join
  if cleaned_number.length == 10
    format_phone_number(cleaned_number)
  elsif cleaned_number.length == 11 and cleaned_number[0] == '1'
    cleaned_number = cleaned_number[1..10]
    format_phone_number(cleaned_number)
  else
    'INVALID'
  end
end


def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def acquire_date(date)
  DateTime.strptime(date, '%m/%d/%Y %H:%M')
end



puts "EventManager initialized."

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read 'form_letter.erb'
erb_template = ERB.new template_letter

reg_days = []
reg_hours = []

contents.each do |row|
  id = row[0]
  date = acquire_date(row[:regdate])
  name = row[:first_name]
  phone_number = validate_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  reg_hours << date.hour
  reg_days << date.wday

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)

end

count = Hash.new(0)

reg_hours.each do |hour| 
  count[hour] += 1
end

common = count.sort_by {|k,v| v}.last

puts "The most common hour of registration is #{common[0]} with #{common[1]} occurences."



count = Hash.new(0)
reg_days.each do |day|
  count[day] += 1
end

common = count.sort_by {|k, v| v}.last

puts "The most common day of registration is #{common[0]} (Sunday is 0) with #{common[1]} occurences."