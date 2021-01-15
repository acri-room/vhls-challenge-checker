require 'rexml/document'

doc = REXML::Document.new(File.new(ARGV[0]))

puts "ff=#{doc.elements['profile/AreaEstimates/Resources/FF'].text}"
puts "lut=#{doc.elements['profile/AreaEstimates/Resources/LUT'].text}"
puts "dsp=#{doc.elements['profile/AreaEstimates/Resources/DSP'].text}"
puts "bram=#{doc.elements['profile/AreaEstimates/Resources/BRAM_18K'].text}"
puts "uram=#{doc.elements['profile/AreaEstimates/Resources/URAM'].text}"
puts "clock_period=#{doc.elements['profile/PerformanceEstimates/SummaryOfTimingAnalysis/EstimatedClockPeriod'].text}"
