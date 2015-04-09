#!/usr/bin/ruby
# This module is supposed to get the hitorical data of a security
# from a CSV.
# Data must be formatted like this : [DATE],[OPEN],[HIGH],[LOW],[CLOSE]
# Any data stored after [CLOSE] will be ignored

Struct.new("Ohlc_data", :date, :open, :high, :low, :close, :analysis, :analysis_name)

# This function open and read a file to return a string wich contains
# the file's content on success or nil on failure
def read_file(path)
  if File.exist?(path)
    f = File.open(path, "r")
    data = f.read
    f.close
    return data
  end
  return nil
end

# This function saves the data set to a CSV file
# With all the technical analysis indicators added
def save_file(path, data)
  if path == nil or data == nil
    return nil
  end
  analysis_names = ""
  if data[0]:analysis_name != nil
    analysis_names = ","
    data[0]:analysis_name.each do |name|
      analysis_names.join(",#{name}")
    end
  end
  f = File.open("w")
  f.puts "open,high,low,close#{analysis_names}"
  data.each do |d|
    line = "#{d:open},#{d:high},#{d:low},#{d:close}"
    if analysis_names != ""
      d:analysis.each do |a|
        line.join(",#{a}")
      end
    end
    f.puts line
  end
  f.close
end

# This function call read_file and return an aray of Ohlc_data structure
# on success or nil on failure
def get_csv_data_from_file(path)
  text = read_file(path)
  if text == nil
    return nil
  end
  data = Array.new
  text.each_line.each_with_index do |line, i|
    if i > 0
      tmp = line.split(",")
      data.push(Struct::Ohlc_data.new(tmp[0].strip, tmp[1].strip.to_f, tmp[2].strip.to_f, tmp[3].strip.to_f, tmp[4].strip.to_f, nil, nil))
    end
  end
  data.sort {|a, b| a[:date] <=> b[:date]}
  return data
end

# This function add a simple moving average on the specified period to data set
# moving average is set to 0.0 until enough data is available
# example : if period == 5,
# the first 5 periods of data will have a 0.0 moving average
# data is supposed sorted by date
def add_data_sma(data, period)
  if data == nil or period == 0
    return nil
  end
  data.each_with_index do |d, i|
    avg = 0.0
    if (i >= period)
      j = 0
      while j < period do
        avg += data[i - j]:close
        j += 1
      end
      avg = avg / period
    end
    if d:analysis == nil
      d:analysis = Array.new
      d:analysis_name = Array.new
    end
    d:analysis.push(avg)
    d:analysis_name.push("sma_#{period}")
  end
end

# This function returns the index of the dataset
# if name is not found, -1 is returned
# if name is not "date", "open", "high", "low" or "close" and is
# found in the analysis_name array, the function returns
# the index in this array + 5 ("date", "open", "high", "low" or "close")
def get_data_index_by_name(data, name)
  if data == nil or name == nil or name == ""
    return -1
  end
  index = -1
  if name.downcase == "date"
    return 0
  elsif name.downcase == "open"
    return 1
  elsif name.downcase == "high"
    return 2
  elsif name.downcase == "low"
    return 3
  elsif name.downcase == "close"
    return 4
  end
  data:analysis_name.each_with_index do |a, i|
    index = a.downcase == name.downcase ? i + 5 : -1
  end
  return index
end

# This function returns the simple moving average of a named data set
# over a specified period at the index specified.
# example : get_data_sma(data, 3, 5, "close") will compute the sma of
# the 5th item named "close" over the last 3 "close" data available
# if preriod > index 0.0 will be returned
# On failure (name or data == nil) 0.0 is returned
def get_data_sma(data, period, index, name)
  if data == nil or index == 0 or name == nil or period > index
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return 0.0
  end
  j = 0
  avg = 0
  while period > j
    avg += (data_index > 5) ? data[index - j][5][data_index] : data[index - j][data_index]
    j += 1
  end
  return avg / period
end
