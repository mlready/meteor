(function() {
  var Promise, buildHardware, buildHardwareParameters, dates, fs, mongodb, parseXml, parser, xml2js, _;

  Promise = require('bluebird');

  fs = require('fs');

  xml2js = require('xml2js');

  _ = require('underscore');

  mongodb = require('mongodb');

  parser = new xml2js.Parser();

  dates = {
    createdAt: new Date(),
    updatedAt: new Date()
  };

  buildHardwareParameters = function(properties) {
    var columnHardwareParameters;
    columnHardwareParameters = {
      internalBedDiameter: {
        amount: properties.internalBedDiameter,
        unit: "CENTIMETERS"
      },
      internalBedHeight: {
        amount: properties.internalBedHeight,
        unit: "CENTIMETERS"
      },
      internalVolume: {
        amount: properties.internalVolume,
        unit: "MILLILITERS"
      },
      maximumWorkingPressure: {
        amount: 20.0,
        unit: "MEGAPASCALS"
      },
      minimumPhWhenNotRunning: {
        amount: 0.0,
        unit: "PH"
      },
      maximumPhWhenNotRunning: {
        amount: 14.0,
        unit: "PH"
      },
      minimumPhWhenRunning: {
        amount: 0.0,
        unit: "PH"
      },
      maximumPhWhenRunning: {
        amount: 14.0,
        unit: "PH"
      }
    };
    return columnHardwareParameters;
  };

  buildHardware = function(columnTypes) {
    var columnBedHeightInCentimeters, columnHardwareToInsert, columnHardwares, columnType, diameterInCentimeters, hardware, hardwareName, hardwareProperties, volumeInMilliliters, _i, _len;
    columnHardwares = {};
    for (_i = 0, _len = columnTypes.length; _i < _len; _i++) {
      columnType = columnTypes[_i];
      hardware = columnType.Hardware[0];
      columnBedHeightInCentimeters = parseFloat(columnType.BedHeight[0]);
      diameterInCentimeters = parseFloat(hardware.Diameter[0]);
      hardwareName = hardware.Name[0];
      volumeInMilliliters = Math.pow(diameterInCentimeters / 2, 2) * Math.PI * columnBedHeightInCentimeters;
      hardwareProperties = buildHardwareParameters({
        internalBedDiameter: diameterInCentimeters,
        internalBedHeight: columnBedHeightInCentimeters,
        internalVolume: volumeInMilliliters
      });
      if (columnHardwares[hardware] == null) {
        columnHardwares[hardwareName] = hardwareProperties;
      }
    }
    columnHardwareToInsert = [];
    for (hardwareName in columnHardwares) {
      hardwareProperties = columnHardwares[hardwareName];
      columnHardwareToInsert.push({
        hardwareName: hardwareName,
        hardwareProperties: hardwareProperties
      });
    }
    return columnHardwareToInsert;
  };

  parseXml = function(data) {
    var columnTypes;
    columnTypes = null;
    parser.parseString(data, function(error, result) {
      if (error) {
        throw error;
      }
      return columnTypes = result.ColumnTypes.ColumnType;
    });
    return columnTypes;
  };

  exports.up = function(db, callback) {
    var columnHardwareDb;
    columnHardwareDb = mongodb.Collection(db, 'columnHardware');
    Promise.promisifyAll(db);
    Promise.promisifyAll(fs);
    Promise.promisifyAll(columnHardwareDb);
    return fs.readFileAsync('assets/import-column-types.xml').then(parseXml).then(buildHardware).map(function(result) {
      var hardware, hardwareName, hardwareProperties;
      hardwareName = result.hardwareName, hardwareProperties = result.hardwareProperties;
      hardware = {
        name: hardwareName.trim(),
        manufacturer_id: 1,
        description: "",
        isEnabled: "ENABLED",
        properties: hardwareProperties,
        dates: dates
      };
      return columnHardwareDb.insertAsync(hardware);
    }).reduce(function(count, updateResult) {
      return count + 1;
    }, 0).then(function(count) {
      return console.log("Column hardware loaded: ", count);
    }).then(callback)["catch"](callback);
  };

  exports.down = function(db, callback) {
    return callback();
  };

}).call(this);
