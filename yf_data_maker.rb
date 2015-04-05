#!/usr/bin/ruby
# This module is supposed to get the hitorical data of a seurity
# from a CSV.
# Data must be formatted like this : [DATE],[OPEN],[HIGH],[LOW],[CLOSE]
# Any data stored after [CLOSE] will be ignored

Struct.new("Ohlc_data", :date, :open, :high, :low, :close, :analysis)

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
      data.push(Struct::Ohlc_data.new(tmp[0].strip, tmp[1].strip.to_f, tmp[2].strip.to_f, tmp[3].strip.to_f, tmp[4].strip.to_f, nil))
    end
  end
  data.sort {|a, b| a[:date] <=> b[:date]}
  return data
end

# This function add a moving average on the specified period to data set
# moving average is set to 0.0 until enough data is available
# example : if period == 5,
# the first 5 periods of data will have a 0.0 moving average
# data is supposed sorted by date
def add_data_mov_avg(data, period)
  if data == nil or period == 0
    return nil
  end
  data.each_with_index do |d, i|
    avg = 0.0
    if (i >= period)
      j = 0
      while j < period do
        avg += data[i - j]
        j += 1
      end
      avg = avg / period
    end
    if d:analysis == nil
      d:analysis = Array.new
    end
    d:analysis.push(avg)
  end
end
