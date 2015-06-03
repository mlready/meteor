Promise = require('bluebird')
fs = require('fs')
mongodb = require('mongodb')
xml2js = require('xml2js')
_ = require('underscore')
parser = new xml2js.Parser()

columnMediaKeys = {}
columnHardwareKeys = {}

dates =
	createdAt: new Date()
	updatedAt: new Date()
	
loadColumnMediaKeys = (results) ->
	results.forEach((result) ->
		id = result._id
		column_media_name = result.name
		columnMediaKeys[column_media_name] = id
	)
	
loadColumnHardwareKeys = (results) ->
	results.forEach((result) ->
		id = result._id
		column_hardware_name = result.name
		columnHardwareKeys[column_hardware_name] = id
	)

buildColumnParameters = (properties) ->
	columnParameters = 
		inletPressureLimit: 
			amount: properties.inletPressureLimit
			unit: "MEGAPASCALS"
		inletToOutletPressureLimit: 
			amount: properties.inletToOutletPressureLimit
			unit: "MEGAPASCALS"
		columnVolumeSize: 
			amount: properties.columnVolumeSize
			unit: "MILLILITERS"
		maximumFlowRate: 
			amount: properties.maximumFlowRate
			unit: "MILLILITERS_PER_MINUTE"
	columnParameters

parseXml = (data) ->
	columnTypes = null
	parser.parseString(data, (error, result) ->
		if (error)
			throw error
		columnTypes = result.ColumnTypes.ColumnType
	)
	columnTypes	

buildColumns = (columnTypes) ->
	columnsToInsert = []
	for columnType in columnTypes
		media = columnType.Media[0]
		mediaName = media.Name[0].trim()
		hardware = columnType.Hardware[0]
		hardwareName = hardware.Name[0].trim()
		
		defaultFlowRateInMillilitersPerMinute = parseFloat(columnType.DefaultFlowrate[0])
		technique = media.TechniqueName[0].trim()
		columnDescription =  """#{hardwareName} - #{mediaName}"""
		columnName = columnType.Name[0].trim()
		
		columnMaximumFlowrateInMillilitersPerMinute = parseFloat(columnType.MaxFlowrate[0])
		deltaColumnPressureInMegaPascals = parseFloat(columnType.DeltaColumnPressure[0])
		preColumnPressureInMegaPascals = parseFloat(hardware.PreColumnPressure[0])
		
		totalLiquidVolumeInMilliliters = null
		totalLiquidVolumeInMilliliters = parseFloat(columnType.TotalLiquidVolume[0]) if columnType.TotalLiquidVolume?
		
		voidVolumeInMilliliters = null
		voidVolumeInMilliliters = parseFloat(columnType.VoidVolume[0]) if columnType.VoidVolume?
		
		bedDiameterInCentimeters = parseFloat(hardware.Diameter)
		bedHeightInCentimeters = parseFloat(columnType.BedHeight)
		calculatedVolumeInMilliliters = bedHeightInCentimeters * Math.pow((bedDiameterInCentimeters / 2), 2) * Math.PI
		
		if totalLiquidVolumeInMilliliters? && !voidVolumeInMilliliters?
			if totalLiquidVolumeInMilliliters > calculatedVolumeInMilliliters
				# This seems unlikely so ignoring any column types where this occurs
				continue
		
		voidVolumeInMilliliters = totalLiquidVolumeInMilliliters unless voidVolumeInMilliliters?
		
		techniqueType = null
		switch technique
			when "AnionExchange"
				techniqueType = "ANION_EXCHANGE"
			when "CationExchange"
				techniqueType = "CATION_EXCHANGE"
			when "HIC"
				techniqueType = "HIC"
			when "Affinity"
				techniqueType = "AFFINITY"
			when "GelFiltration"
				techniqueType = "GEL_FILTRATION"
			when "Desalting"
				techniqueType = "DESALTING"
			when "Any"
				techniqueType = "MULTIPLE_TECHNIQUES"
			else
				# The above are the only types we support so ignore any others
				continue
				
		columnProperties = buildColumnParameters({
			inletPressureLimit: preColumnPressureInMegaPascals, 
			inletToOutletPressureLimit: deltaColumnPressureInMegaPascals, 
			columnVolumeSize: parseFloat(voidVolumeInMilliliters)
			maximumFlowRate: columnMaximumFlowrateInMillilitersPerMinute})

		column_media_id = columnMediaKeys[mediaName]
		column_hardware_id = columnHardwareKeys[hardwareName]
		
		columnsToInsert.push({columnName, column_media_id, column_hardware_id, columnDescription, columnProperties, techniqueType })
	columnsToInsert

exports.up = (db, callback) ->
	
	Collection = mongodb.Collection
	Promise.promisifyAll(Collection.prototype)

	columnsDb = Collection(db, 'columns')
	columnHardwareDb = Collection(db, 'columnHardware')
	columnMediaDb = Collection(db, 'columnMedia')
	fs = Promise.promisifyAll(fs)
	
	Collection.prototype._find = Collection.prototype.find
	Collection.prototype.find = ->
		cursor = this._find.apply(this, arguments)
		#cursor.toArrayAsync = Promise.promisify(cursor.toArray, cursor)
		#cursor.countAsync = Promise.promisify(cursor.count, cursor)
		Promise.promisifyAll(cursor)
		return cursor

				
	columnMediaDb.find({}, {_id: true, name: true}).toArrayAsync()
		.then(loadColumnMediaKeys)
		.then(->
			columnHardwareDb.find({}, {_id: true, name: true}).toArrayAsync()
		)
		.then(loadColumnHardwareKeys)
		.then(->
			fs.readFileAsync('assets/import-column-types.xml')
		)
		.then(parseXml)
		.then( buildColumns )
		.map( (result) ->
			{columnName, column_media_id, column_hardware_id, columnDescription, columnProperties, techniqueType} = result
			column =
				name: columnName.trim()
				technique: techniqueType.trim()
				isEnabled: "ENABLED"
				manufacturer_id: 1
				columnMedia_id: column_media_id
				columnHardware_id: column_hardware_id
				description: columnDescription.trim()
				properties: columnProperties
				dates: dates
			
			columnsDb.insertAsync(column)	
		).reduce((count, updateResult) ->
			return count + 1
		0).then((count) ->
			console.log "Columns loaded: ", count
		).then(callback)
		.catch(callback)

exports.down = (db, callback) ->
	callback()
	