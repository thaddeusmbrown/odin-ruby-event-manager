require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.to_s.scan(/\d/).join('')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number.slice(0, 1) == '1'
    phone_number.slice(1, 10)
  else
    '0000000000'
  end
end

def clean_date(date)
  date = DateTime.strptime(date, '%m/%d/%Y %k:%M')
  DateTime.new(date.year + 2000, date.month, date.day, date.hour, date.min, date.offset)
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone_number = clean_phone_number(row[:homephone])
  regdate = clean_date(row[:regdate])

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  signup_hour = regdate.hour

  signup_day = regdate.strftime('%a')

  save_thank_you_letter(id, form_letter)
end
