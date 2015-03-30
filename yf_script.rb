#!/usr/bin/ruby
require 'open-uri'

#ticker = "FP.PA"

Struct.new("Fin_period", :date, :open, :high, :low, :close, :volume, :adj_close)

def write_data_set_to_file(dataset, path)
	f = File.new(path, "w")
	dataset.each do |elem|
				 f.puts "#{elem[:date]}, #{elem[:open]}, #{elem[:high]}, #{elem[:low]}, #{elem[:close]}, #{elem[:volume]}, #{elem[:adj_close]}"
	end
	f.close
end

def make_data_set(raw_data)
	lines = raw_data.each_line
	data_set = Array.new
	lines.each do |line|
			   tmp = line.split(",")
			   if tmp[0] == "Date"
			   	  	data_set.push(Struct::Fin_period.new(tmp[0], tmp[1], tmp[2], tmp[3], tmp[4], tmp[5], tmp[6]))
			   else
					data_set.push(Struct::Fin_period.new(tmp[0], tmp[1].to_f, tmp[2].to_f, tmp[3].to_f, tmp[4].to_f, tmp[5].to_f, tmp[6].to_f))
			   end
	end
	data_set.sort {|x, y| y[:date] <=> x[:date]}
	return data_set
end

def puts_data_set(dataset)
	dataset.each do |elem|
		puts "Date : #{elem[:date]}"
		puts "Open : #{elem[:open]}"
		puts "High : #{elem[:high]}"
		puts "Low : #{elem[:low]}"
		puts "Close : #{elem[:close]}"
		puts "Volume : #{elem[:volume]}"
		puts "Adj close : #{elem[:adj_close]}"
	end
end

def data_set_mov_avg(dataset, period)
	sum = 0.0
	i = 0
	while dataset[i] != nil and i < period
		  if dataset[i][:close] == "Close"
		  	 period += 1
		  else
			 sum += dataset[i][:close]
			end
		  i += 1
	end
return sum / period
end

while 1 == 1 do

puts "What's the yahoo ticker of desired value ? (type 0 to quit)"
ticker = gets.strip.upcase
if ticker == "0"
   exit 0
end
puts "What do you want ?"
puts "1) Get the last data"
puts "2) Get the historical data (daily, weekly and monthly)"
puts "3) Use another ticker"
ans = gets.strip
if ans == "1"
   yf_options = "nsl1j1b4m3s6j4"
   yf_opt_name = ["Name", "Ticker", "Last price", "Market cap", "Book value", "50 day mov avg", "Revenue", "EBITDA"]
   path = "/d/quotes.csv?s=#{ticker}&f=#{yf_options}&e=.csv"
   data = open("http://download.finance.yahoo.com#{path}").read
   tab = data.split(",")
   i = 0
   tab.each do |tab|
   				puts "#{yf_opt_name[i]} : #{tab}"
				i = i + 1
	end
elsif ans == "2"
	  start_date = ""
	  while start_date.match(/([0-9]{2}\/){2}[0-9]{4}/) == nil do
	  	  puts "From wich date ? (dd/mm/yyyy)"
	  	  start_date = gets.strip
	end
	  end_date = ""
	  while end_date.match(/([0-9]{2}\/){2}[0-9]{4}/) == nil do
	  	  puts "To wich date ? (dd/mm/yyyy)"
	  	  end_date = gets.strip
	end
	  frequency = ""
	  while frequency.match(/\A[d,w,m]\z/) == nil do
	  	  puts "At wich frequency ? (d = daily, w = weekly, m = monthly)"
		  frequency = gets.strip.downcase
	end
	start_tab = start_date.split("/")
	end_tab = end_date.split("/")
	url = "http://real-chart.finance.yahoo.com/table.csv?s=#{ticker}&d=#{end_tab[1].to_i-1}&e=#{end_tab[0]}&f=#{end_tab[2]}&g=#{frequency}&a=#{start_tab[1].to_i-1}&b=#{start_tab[0]}&c=#{start_tab[2]}&ignore=.csv"
	puts url
	data = open(url).read
	puts "The data have #{data.lines.count} lines, do you want to see them all ? (y/n)"
	yn_res = ""
	while yn_res.downcase.match(/\A[y,n]\z/) == nil do
		yn_res = gets.strip
	end
	if yn_res == "y"
	   puts "#{data}"
	   data_set = make_data_set(data)
	   puts_data_set(data_set)
	   puts data_set_mov_avg(data_set, 20)
	   write_data_set_to_file(data_set, "./testfile")
	end
end
end