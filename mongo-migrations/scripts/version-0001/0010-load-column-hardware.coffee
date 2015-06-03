Promise = require('bluebird')
fs = require('fs')
xml2js = require('xml2js')
_ = require('underscore')
mongodb = require('mongodb')

parser = new xml2js.Parser()

dates =
	createdAt: new Date()
	updatedAt: new Date()
	
buildHardwareParameters = (properties) ->
	columnHardwareParameters = 
		internalBedDiameter: 
			amount: properties.internalBedDiameter
			unit: "CENTIMETERS"
		internalBedHeight: 
			amount: properties.internalBedHeight
			unit: "CENTIMETERS"
		internalVolume: 
			amount: properties.internalVolume
			unit: "MILLILITERS"
		maximumWorkingPressure: 
			amount: 20.0
			unit: "MEGAPASCALS"
		minimumPhWhenNotRunning: 
			amount: 0.0
			unit: "PH"
		maximumPhWhenNotRunning: 
			amount: 14.0
			unit: "PH"
		minimumPhWhenRunning: 
			amount: 0.0
			unit: "PH"
		maximumPhWhenRunning: 
			amount: 14.0
			unit: "PH"
	columnHardwareParameters

buildHardware = (columnTypes) ->
	columnHardwares = {}

	for columnType in columnTypes
		hardware = columnType.Hardware[0]
		columnBedHeightInCentimeters = parseFloat(columnType.BedHeight[0])
		diameterInCentimeters = parseFloat(hardware.Diameter[0])
		hardwareName = hardware.Name[0]
		volumeInMilliliters = Math.pow((diameterInCentimeters /2), 2) * Math.PI * columnBedHeightInCentimeters
				
		hardwareProperties = buildHardwareParameters({
			internalBedDiameter: diameterInCentimeters, 
			internalBedHeight: columnBedHeightInCentimeters, 
			internalVolume: volumeInMilliliters})
		
		# Using a collection since hardware is duplicated across multiple columns in the file
		columnHardwares[hardwareName] = hardwareProperties unless columnHardwares[hardware]?
	
	# Converting the result to an array for the map function
	columnHardwareToInsert = []
	for hardwareName, hardwareProperties of columnHardwares
		columnHardwareToInsert.push({hardwareName, hardwareProperties})
	columnHardwareToInsert

parseXml = (data) ->
	columnTypes = null
	parser.parseString(data, (error, result) ->
		if (error)
			throw error
		columnTypes = result.ColumnTypes.ColumnType
	)
	columnTypes
	
exports.up = (db, callback) ->
	columnHardwareDb = mongodb.Collection(db, 'columnHardware')
	Promise.promisifyAll(db)
	Promise.promisifyAll(fs)
	Promise.promisifyAll(columnHardwareDb)
	
	fs.readFileAsync('assets/import-column-types.xml')
		.then(parseXml)
		.then( buildHardware )
		.map( (result) ->
			{hardwareName, hardwareProperties} = result
			hardware =
				name: hardwareName.trim()
				manufacturer_id: 1
				description: ""
				isEnabled: "ENABLED"
				properties: hardwareProperties
				dates: dates
				
			columnHardwareDb.insertAsync(hardware)
		).reduce((count, updateResult) ->
			return count + 1
		0).then((count) ->
			console.log "Column hardware loaded: ", count
		).then(callback)
		.catch(callback)

exports.down = (db, callback) ->
	callback()