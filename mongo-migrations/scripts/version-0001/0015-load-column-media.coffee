Promise = require('bluebird')
fs = require('fs')
xml2js = require('xml2js')
_ = require('underscore')
mongodb = require('mongodb')

parser = new xml2js.Parser()

dates =
	createdAt: new Date()
	updatedAt: new Date()
	
buildMediaProperties = (properties) ->
	columnMediaParameters = 
		inletPressureLimit:
			amount: properties.inletPressureLimit
			unit: "MEGAPASCALS"
		inletToOutletPressureLimit:
			amount: properties.inletToOutletPressureLimit
			unit: "MEGAPASCALS"
		minimumPhWhenNotRunning:
			amount: properties.minimumPhWhenNotRunning
			unit: "PH"
		maximumPhWhenNotRunning:
			amount: properties.maximumPhWhenNotRunning
			unit: "PH"
		minimumPhWhenRunning:
			amount: properties.minimumPhWhenRunning
			unit: "PH"
		maximumPhWhenRunning:
			amount: properties.maximumPhWhenRunning
			unit: "PH"
		typicalFlowRate:
			amount: properties.typicalFlowRate
			unit: "MILLILITERS_PER_MINUTE"
		maximumFlowRate:
			amount: properties.maximumFlowRate,
			unit: "MILLILITERS_PER_MINUTE"
		equivalentColumnVolume:
			amount: 0
			unit: "MILLILITERS"
		averageParticleDiameter:
			amount: properties.averageParticleDiameter
			unit: "MICROMETERS"
	columnMediaParameters

parseXml = (data) ->
	columnTypes = null
	parser.parseString(data, (error, result) ->
		if (error)
			throw error
		columnTypes = result.ColumnTypes.ColumnType
	)
	columnTypes	
		
buildMedia = (columnTypes) ->
	columnMedia = {}
	for columnType in columnTypes
		media = columnType.Media[0]
		hardware = columnType.Hardware[0]
		mediaName = media.Name[0]
		minimumPhShortTerm = parseFloat(media.MinpHShortTerm[0])
		minimumPhLongTerm = parseFloat(media.MinpHLongTerm[0])
		maximumPhShortTerm = parseFloat(media.MaxpHShortTerm[0])
		maximumPhLongTerm = parseFloat(media.MaxpHLongTerm[0])
		averageParticleDiameterInMicrometers = parseFloat(media.AverageParticleDiameter[0])
		defaultFlowRateInMillilitersPerMinute = parseFloat(columnType.DefaultFlowrate[0])
		columnMaximumFlowrateInMillilitersPerMinute = parseFloat(columnType.MaxFlowrate[0])
		deltaColumnPressureInMegaPascals = parseFloat(columnType.DeltaColumnPressure[0])
		
		preColumnPressureInMegaPascals = parseFloat(hardware.PreColumnPressure[0])
				
		mediaProperties = buildMediaProperties({
			inletPressureLimit: preColumnPressureInMegaPascals, 
			inletToOutletPressureLimit: deltaColumnPressureInMegaPascals, 
			minimumPhWhenRunning: minimumPhShortTerm, 
			minimumPhWhenNotRunning: minimumPhLongTerm, 
			maximumPhWhenRunning: maximumPhShortTerm, 
			maximumPhWhenNotRunning: maximumPhLongTerm, 
			typicalFlowRate: defaultFlowRateInMillilitersPerMinute, 
			maximumFlowRate: columnMaximumFlowrateInMillilitersPerMinute, 
			averageParticleDiameter: averageParticleDiameterInMicrometers})
		
		columnMedia[mediaName] = mediaProperties unless columnMedia[mediaName]?
		
	# Converting the result to an array for the map function
	columnMediaToInsert = []
	for mediaName, mediaProperties of columnMedia
		columnMediaToInsert.push({mediaName, mediaProperties})
	
	columnMediaToInsert

exports.up = (db, callback) ->
	columnMediaDb = mongodb.Collection(db, 'columnMedia')
	Promise.promisifyAll(columnMediaDb)
	Promise.promisifyAll(fs)
	
	fs.readFileAsync('assets/import-column-types.xml')
		.then( parseXml )
		.then( buildMedia )
		.map( (result) ->
			{mediaName, mediaProperties} = result
			columnMedia =
				name: mediaName.trim()
				manufacturer_id: 1
				description: ""
				isEnabled: "ENABLED"
				properties: mediaProperties
				dates: dates
				
			columnMediaDb.insertAsync(columnMedia)
		).reduce((count, updateResult) ->
			return count + 1
		0).then((count) ->
			console.log "Column media loaded: ", count
		).then(callback)
		.catch(callback)

exports.down = (db, callback) ->
	callback()
	