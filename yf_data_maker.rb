#!/usr/bin/ruby
# This script is supposed to get the hitorical data of a security
# from a CSV.
# Data must be formatted like this : [DATE],[OPEN],[HIGH],[LOW],[CLOSE]
# Any data stored after [CLOSE] will be ignored
# Some technical indicators needs multiple columns, example : bollinger bands 20, 2
# needs 3 columns : boll_sma_20, boll_20_2_up and boll_20_2_down
# Indicators which needs multiples columns use all the columns they need to work
# The purpose of this script is to edit data for further use by another software
# wich is not able to do these edits (Excel, what a shame, can't make an exponential moving average)
# NB : data won't be duplicated if they already exists and already existing data will be used
# to compute advanced indicators, example :
# you already have a simple moving average over 20 periods (sma_20) and you want to add
# bollinger bands over 20 periods and a standard deviation multiplier of 2 (boll_bands(20,2))
# the script will use the already existing sma_20 and won't compute a special one for the boll_bands
# Ruby is not that fast, so I try to avoid unnecessary memory operations wich are slowing down
# the process even in faster languages like C.

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
  if data[0][:analysis_name] != nil
    analysis_names = ","
    data[0][:analysis_name].each do |name|
      analysis_names << ",#{name}"
    end
  end
  f = File.open(path.strip, "w")
  f.puts "date,open,high,low,close,#{analysis_names}"
  data.each do |d|
    line = "#{d[:date]},#{d[:open]},#{d[:high]},#{d[:low]},#{d[:close]}"
    if analysis_names != ""
      d[:analysis].each do |a|
        line << ",#{a}"
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
  puts "#{data.class}"
  data[0][:analysis_name].each_with_index do |a, i|
    index = a.downcase == name.downcase ? i + 5 : index
  end
  return index
end

# This function returns the simple moving average of a named data set
# over a specified period at the index specified.
# example : get_data_sma(data, 3, 5, "close") will compute the sma of
# the 5th item named "close" over the last 3 "close" data available
# if preriod > index 0.0 will be returned
# On failure (name or data == nil) 0.0 is returned
def get_data_sma(data, index, period, name)
  if data == nil or name == nil or period > index
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return 0.0
  end
  j = 0
  avg = 0.0
  while period > j
    avg = (data_index > 5) ? data[index - j][5][data_index - 5] : data[index - j][data_index]
    j += 1
  end
  return avg / period
end

def get_data_variance(data, index, period, name)
  if data == nil or index == 0 or name == nil or period > index
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return 0.0
  end
  avg = 0.0
  j = 0
  while j < period
    avg += (data_index > 5) ? data[index - j][5][data_index - 5] : data[index - j][data_index]
    j += 1
  end
  avg = avg / period
  j = 0
  sum = 0.0
  while j < period
    res = (data_index > 5) ? data[index - j][5][data_index - 5] : data[index - j][data_index]
    res = res - avg
    res = res * res
    sum += res
    j += 1
  end
  return res / (period - 1)
end

def get_data_standard_deviation(data, index, period, name)
  if data == nil or index == 0 or name == nil or period > index
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return 0.0
  end
  var = get_data_variance(data, index, period, name)
  if var == nil
    return nil
  end
  return Math.sqrt(var)
end

# This this function compute and returns the exponential moving average of
# the specified element, over the period specified and at the index specified
def get_data_ema(data, index, period, name)
  if data == nil or index == 0 or name == nil or period > index
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return 0.0
  end
  if period == index
    return get_data_sma(data, index, period, name)
  else
    data_index = get_data_index_by_name(data, name)
    t_price = (data_index > 5) ? data[index][5][data_index - 5] : data[index][data_index]
    y_ema = get_data_ema(data, index, period - 1, name)
    t_ema = y_ema + ((2 / (period + 1)) * (t_price - y_ema))
    return t_ema
  end
end

# This exponential moving average is only used in RSI calculation because the "real EMA"
# use all the data and the RSI needs all the up and all the down over N days
# This function's data is an array of all up or all down over the period
def get_data_ema_rsi(data, index)
  if data == nil or index < 0 or data.count == 0
    return 0.0
  end
  if index == data.count - 1
    return data[0]
  end
  alpha = 2 / (1 + data.count)
  y_ema = get_data_ema_rsi(data, index - 1)
  return data[index] * alpha + y_ema * (1 - alpha)
end

def get_data_rsi(data, index, period, name)
  if data == nil or index == 0 or name == nil or period > index
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return 0.0
  end
  ups = Array.new
  downs = Array.new
  i = 0
  while i < period
    t_data = (data_index > 5 ? data[index - i][5][data_index - 5] : data[index - i][data_index])
    y_data = (data_index > 5 ? data[index - i - 1][5][data_index - 5] : data[index - i - 1][data_index])
    diff = t_data - y_data
    if diff < 0
      downs.push diff.abs
    else
      ups.push diff
    end
    i += 1
  end
  ema_ups = get_data_ema_rsi(ups, 0)
  ema_downs = get_data_ema_rsi(downs, 0)
  return ((ema_ups / (ema_ups + ema_downs)) * 100)
end

# This function returns the mininum value of name data range
# from start to stop wich are both included
def get_data_min(data, start, stop, name)
  if data == nil or start < 0 or stop < 0 or name == nil
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return 0.0
  end
  if start > stop
    tmp = start
    start = stop
    stop = tmp
  end
  min = (data_index > 5 ? data[start][5][data_index - 5] : data[start][data_index])
  i = start
  while i <= stop
    if (data_index > 5 ? data[i][5][data_index - 5] : data[i][data_index]) < min
      min = (data_index > 5 ? data[i][data_index - 5] : data[i][data_index])
    end
    i += 1
  end
  return min
end

def get_data_max(data, start, stop, name)
  if data == nil or start < 0 or stop < 0 or name == nil
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return 0.0
  end
  if start > stop
    tmp = start
    start = stop
    stop = tmp
  end
  max = (data_index > 5 ? data[start][5][data_index - 5] : data[start][data_index])
  i = start
  while i <= stop
    if (data_index > 5 ? data[i][5][data_index - 5] : data[i][data_index]) > max
      max = (data_index > 5 ? data[i][5][data_index - 5] : data[i][data_index])
    end
    i += 1
  end
  return max
end

# This function returns the %K of a stochastic
# To get the %D of a stochastic, just do an sma (usually on 3 periods) on the %D data range
def get_data_stochastic_k(data, index, period, name)
  if data == nil or index == 0 or period == 0 or name == nil or period > index
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return (0.0)
  end
  price = data_index > 5 ? data[index][5][data_index - 5] : data[index][data_index]
  h = get_data_max(data, index, index - period, name)
  b = get_data_min(data, index, index - period, name)
  return (100 * (price - b) / (h - b))
end

# This function returns the Williams %K of data over a period
# NB : Williams %K is always equal to 100 - stochastic's %K over the same period
def get_data_williams_r(data, index, period, name)
  if data == nil or index == 0 or period == 0 or name == nil or period > index
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return (0.0)
  end
  return (100 - get_data_stochastic_k(data, index, period, name))
end

# This function returns the MACD value of data over the specified periods (period1 and period2)
# NB : This returns only the difference of the two EMAs, to get the EMAs value, run get_data_ema
# Quick EMA is calculated using period1 and slow EMA using period2
def get_data_macd(data, index, period1, period2, name)
  if data == nil or index == 0 or period1 == 0 or period2 == 0 or name == nil or period1 > index or period2 > index
    return 0.0
  end
  data_index = get_data_index_by_name(data, name)
  if data_index < 1
    return (0.0)
  end
  ema1 = get_data_ema(data, index, period1, name)
  ema2 = get_data_ema(data, index, period2, name)
  return (ema2 - ema1)
end

# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# The following part of the script is add functions' part
# <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

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
    avg = get_data_sma(data, i, period, "close")
    if d[:analysis] == nil
      d[:analysis] = Array.new
      d[:analysis_name] = Array.new
    end
    d[:analysis].push(avg)
    d[:analysis_name].push("sma_#{period}")
  end
end

def add_data_rsi(data, period)
  if data == nil or period == 0
    return nil
  end
  data.each_with_index do |d, i|
    rsi = get_data_rsi(data, i, period, "close")
    if d[:analysis] == nil
      d[:analysis] = Array.new
      d[:analysis_name] = Array.new
    end
    d[:analysis].push(rsi)
    d[:analysis_name].push("rsi_#{period}")
  end
end

def add_data_stochastic_k(data, period)
  if data == nil or period == 0
    return nil
  end
  data.each_with_index do |d, i|
    stoch = get_data_stochastic_k(data, i, period, "close")
    if d[:analysis] == nil
      d[:analysis] = Array.new
      d[:analysis_name] = Array.new
    end
    d[:analysis].push(stoch)
    d[:analysis_name].push("stoch_k_#{period}")
  end
end

def add_data_stochastic_d(data, period, name)
  if data == nil or period == 0
    return nil
  end
  prev_period = name.split("_")[2]
  data.each_with_index do |d, i|
    d[:analysis].push(get_data_sma(data, i, period, name))
    d[:analysis_name].push("stoch_#{prev_period}_d_#{period}")
  end
end

def add_data_stochastic_all(data, period1, period2)
  if data == nil or period1 == 0 or period2 == 0
    return nil
  end
  add_data_stochastic_k(data, period1)
  add_data_stochastic_d(data, period2, "stoch_k_#{period1}")
end

def add_data_williams_r(data, period)
  if data == nil or period == 0
    return nil
  end
  data.each_with_index do |d, i|
    wr = get_data_williams_r(data, i, period, "close")
    if d[:analysis] == nil
      d[:analysis] = Array.new
      d[:analysis_name] = Array.new
    end
    d[:analysis].push(wr)
    d[:analysis_name].push("williams_r_#{period}")
  end
end

def add_data_macd(data, period1, period2)
  if data == nil or period1 == 0 or period2 == 0
    return nil
  end
  data.each_with_index do |d, i|
    macd = get_data_macd(data, i, period1, period2, "close")
    if d[:analysis] == nil
      d[:analysis] = Array.new
      d[:analysis_name] = Array.new
    end
    d[:analysis].push(macd)
    d[:analysis_name].push("macd_#{period}")
  end
end

def data_maker_menu_save(data)
  if data == nil
    return 0
  end
  puts("save in : ")
  path = gets
  save_file(path, data)
end

def data_maker_menu()
  data = nil
  while (data == nil)
    puts "Wich file do you want to open ?"
    data = get_csv_data_from_file(gets.strip)
  end
  user_input = String.new
  while (user_input != "exit")
    puts "what what do you want to add ?"
    puts "sma X - Simple Moving Average over X periods"
    #  puts "ema - Exponential Moving Average"
    puts "rsi X - Relative Strenght Index over X periods"
    puts "stoch X Y - Stochastic Oscillator %K over X periods, %D over Y periods"
    puts "will  X - Williams %R over X periods"
    puts "macd X Y - Moving Average Convergence Divergence over X and Y periods"
    puts "save [name] - Save file, optional : filename"
    puts "exit [!] - Exit script, optional : ! means no save prompt"
    user_input = gets.strip
    if user_input.match(/sma [1-9][0-9]*/)
      add_data_sma(data, user_input.split(" ")[1].to_i)
    elsif user_input.match(/rsi [1-9][0-9]*/)
      add_data_rsi(data, user_input.split(" ")[1].to_i)
    elsif user_input.match(/stoch [1-9][0-9]* [1-9][0-9]*/)
      add_data_stochastic_all(data, user_input.split(" ")[1].to_i, user_input.split(" ")[2].to_i)
    elsif user_input.match(/will [1-9][0-9]*/)
      add_data_williams_r(data, user_input.split(" ")[1].to_i)
    elsif user_input.match(/rsi [1-9][0-9]*/)
      add_data_macd(data, user_input.split(" ")[1].to_i, user_input.split(" ")[2].to_i)
    elsif user_input == "save"
      data_maker_menu_save(data)
    end
  end
end

data_maker_menu()
