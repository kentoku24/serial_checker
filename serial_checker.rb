

require 'rubygems'
require 'serialport'
require 'timeout'
require 'pp'

VERSION_SHOULDBE = 200717

USBSERIAL_NAME = "/dev/tty.usbserial-AC00V4M9" #DSD箱なし
#USBSERIAL_NAME = "/dev/tty.usbserial-AG0JO05J" #DSD箱入り
#USBSERIAL_NAME = "/dev/tty.usbserial-DO00BDJU"

puts "起動中..."

#todo 繋げなかった場合のエラーメッセージとか出す
begin
ser = SerialPort.new(USBSERIAL_NAME, 9600, 8, 1, SerialPort::NONE)
rescue Errno::ENOENT => e
	puts "\n\n***************************************************************"
	puts "****** %30s が見つかりません ********" % USBSERIAL_NAME
	puts "********  USBシリアル変換ケーブルを確認してください ***********"
	puts "***************************************************************\n\n"
	throw e
end

puts "準備完了"

line = ''

while true do
	begin
		words = Timeout.timeout(3) do
			ser.gets
		end
		#puts words #.inspect
		line += words
		if line.include? "\n"
			#eval, print, and erase buffer
			values = line.chomp.split(',')
			#pp values
			error = values[1].to_i
			motorL = values[2].to_i
			motorR = values[3].to_i
			heater = values[4].to_i
			batt = values[5].to_i
			sensorL1 = values[6].to_i
			sensorR1 = values[7].to_i
			sensorL2 = values[8].to_i
			sensorR2 = values[9].to_i
			rpmL = values[12].to_i
			rpmR = values[11].to_i
			aen = values[23].to_i
			button = values[24].to_i
			COC_raw = values[27].to_i
			TDOC2_raw = values[28].to_i

			version = values[29].to_i

			error_message = ""

			error_message += "モータL温度:%d 20〜40度ではない, " % motorL if motorL < 20 or 40 < motorL
			error_message += "モータR温度:%d 20〜40度ではない, " % motorR if motorR < 20 or 40 < motorR
			error_message += "ヒータ温度:%d 20〜40度ではない, " % heater if heater < 20 or 40 < heater
			error_message += "バッテリ温度:%d 20〜40度ではない, " % batt if batt < 20 or 40 < batt
			error_message += "バージョン:%d %d であるべき, " % [version, VERSION_SHOULDBE] if version != VERSION_SHOULDBE

			if sensorL1 > 0 or sensorR1 > 0 or sensorL2 > 0 or sensorR2 > 0
				error_message += "センサ L1:%d R1:%d L2:%d R2:%d, " % [sensorL1, sensorR1, sensorL2, sensorR2]
			end
			error_message += "回転数 L:%4d R:%4d, " % [rpmL, rpmR] if rpmL > 5 or rpmR > 5


			if error_message == ""
				puts "OK %s" % line.chomp
			else
				puts "NG %s" % error_message
			end

			#puts "L:%d R:%d heater:%d batt:%d version:%d" % [motorL, motorR, heater, batt, version]



			line = ""
		end


	rescue Timeout::Error
		puts "シリアル線信号なし"
		line = ""
	rescue ArgumentError, TypeError => e
		puts "不完全なデータ"
		line = ""
	end

	#line = ser.gets # read
    #puts line
end
