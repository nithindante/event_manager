require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phonecode(phoneno)
  arr = phoneno.to_s.split("")
  if(arr.length<10)
    return " Its a bad number"
  elsif arr.length == 10
    return arr.join('').to_s
  elsif arr.length == 11
    if arr[0] == '1'
     return arr.drop(1).join('').to_s
    else
    return  'Its a bad number'
    end
  elsif arr.length >= 12
  return  'its a bad number'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody'],
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
arr = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phoneno = clean_phonecode(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])  
  registration_date = row[:regdate]
  arr.push(registration_date)
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id,form_letter)
end

newarr= []

def reg_date_format(arr,newarr)
  arr.each do |date_and_time|
    time_object = Time.strptime(date_and_time, '%m/%d/%y %H:%M').hour
    newarr.push(time_object)
    rescue ArgumentError => e
    puts "Error: #{e.message}"
  end
  freq = newarr.each_with_object(Hash.new(0)) { |v, h| h[v] += 1 }
  most_frequent = freq.max_by { |_, count| count }
  most_frequent_element = most_frequent.first
  return most_frequent_element
end
reg_date_format(arr,newarr)

def highest_no_of_registrations(newarr)
  freq = newarr.each_with_object(Hash.new(0)) { |v, h| h[v] += 1 }
  most_frequent = freq.max_by { |_, count| count }
  most_frequent_element = most_frequent.first
  return most_frequent_element
end

p "The most sutiable time is #{highest_no_of_registrations(newarr)}"