class EtaFormatter
	def self.formatFromSeconds(eta)
		hours, minutes, seconds = self.calculateTimeComponents(eta)
		sprintf("%02d:%02d:%02d", hours, minutes, seconds)
	end

	def self.calculateTimeComponents(timeInSeconds)
		hours = (timeInSeconds / 3600).floor
		timeInSeconds -= hours * 3600

		minutes = (timeInSeconds/60).floor
		timeInSeconds -= minutes * 60

		seconds = timeInSeconds

		return hours, minutes, seconds
	end
end