(function() {
  var Promise, buildMedia, buildMediaProperties, dates, fs, mongodb, parseXml, parser, xml2js, _;

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

  buildMediaProperties = function(properties) {
    var columnMediaParameters;
    columnMediaParameters = {
      inletPressureLimit: {
        amount: properties.inletPressureLimit,
        unit: "MEGAPASCALS"
      },
      inletToOutletPressureLimit: {
        amount: properties.inletToOutletPressureLimit,
        unit: "MEGAPASCALS"
      },
      minimumPhWhenNotRunning: {
        amount: properties.minimumPhWhenNotRunning,
        unit: "PH"
      },
      maximumPhWhenNotRunning: {
        amount: properties.maximumPhWhenNotRunning,
        unit: "PH"
      },
      minimumPhWhenRunning: {
        amount: properties.minimumPhWhenRunning,
        unit: "PH"
      },
      maximumPhWhenRunning: {
        amount: properties.maximumPhWhenRunning,
        unit: "PH"
      },
      typicalFlowRate: {
        amount: properties.typicalFlowRate,
        unit: "MILLILITERS_PER_MINUTE"
      },
      maximumFlowRate: {
        amount: properties.maximumFlowRate,
        unit: "MILLILITERS_PER_MINUTE"
      },
      equivalentColumnVolume: {
        amount: 0,
        unit: "MILLILITERS"
      },
      averageParticleDiameter: {
        amount: properties.averageParticleDiameter,
        unit: "MICROMETERS"
      }
    };
    return columnMediaParameters;
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

  buildMedia = function(columnTypes) {
    var averageParticleDiameterInMicrometers, columnMaximumFlowrateInMillilitersPerMinute, columnMedia, columnMediaToInsert, columnType, defaultFlowRateInMillilitersPerMinute, deltaColumnPressureInMegaPascals, hardware, maximumPhLongTerm, maximumPhShortTerm, media, mediaName, mediaProperties, minimumPhLongTerm, minimumPhShortTerm, preColumnPressureInMegaPascals, _i, _len;
    columnMedia = {};
    for (_i = 0, _len = columnTypes.length; _i < _len; _i++) {
      columnType = columnTypes[_i];
      media = columnType.Media[0];
      hardware = columnType.Hardware[0];
      mediaName = media.Name[0];
      minimumPhShortTerm = parseFloat(media.MinpHShortTerm[0]);
      minimumPhLongTerm = parseFloat(media.MinpHLongTerm[0]);
      maximumPhShortTerm = parseFloat(media.MaxpHShortTerm[0]);
      maximumPhLongTerm = parseFloat(media.MaxpHLongTerm[0]);
      averageParticleDiameterInMicrometers = parseFloat(media.AverageParticleDiameter[0]);
      defaultFlowRateInMillilitersPerMinute = parseFloat(columnType.DefaultFlowrate[0]);
      columnMaximumFlowrateInMillilitersPerMinute = parseFloat(columnType.MaxFlowrate[0]);
      deltaColumnPressureInMegaPascals = parseFloat(columnType.DeltaColumnPressure[0]);
      preColumnPressureInMegaPascals = parseFloat(hardware.PreColumnPressure[0]);
      mediaProperties = buildMediaProperties({
        inletPressureLimit: preColumnPressureInMegaPascals,
        inletToOutletPressureLimit: deltaColumnPressureInMegaPascals,
        minimumPhWhenRunning: minimumPhShortTerm,
        minimumPhWhenNotRunning: minimumPhLongTerm,
        maximumPhWhenRunning: maximumPhShortTerm,
        maximumPhWhenNotRunning: maximumPhLongTerm,
        typicalFlowRate: defaultFlowRateInMillilitersPerMinute,
        maximumFlowRate: columnMaximumFlowrateInMillilitersPerMinute,
        averageParticleDiameter: averageParticleDiameterInMicrometers
      });
      if (columnMedia[mediaName] == null) {
        columnMedia[mediaName] = mediaProperties;
      }
    }
    columnMediaToInsert = [];
    for (mediaName in columnMedia) {
      mediaProperties = columnMedia[mediaName];
      columnMediaToInsert.push({
        mediaName: mediaName,
        mediaProperties: mediaProperties
      });
    }
    return columnMediaToInsert;
  };

  exports.up = function(db, callback) {
    var columnMediaDb;
    columnMediaDb = mongodb.Collection(db, 'columnMedia');
    Promise.promisifyAll(columnMediaDb);
    Promise.promisifyAll(fs);
    return fs.readFileAsync('assets/import-column-types.xml').then(parseXml).then(buildMedia).map(function(result) {
      var columnMedia, mediaName, mediaProperties;
      mediaName = result.mediaName, mediaProperties = result.mediaProperties;
      columnMedia = {
        name: mediaName.trim(),
        manufacturer_id: 1,
        description: "",
        isEnabled: "ENABLED",
        properties: mediaProperties,
        dates: dates
      };
      return columnMediaDb.insertAsync(columnMedia);
    }).reduce(function(count, updateResult) {
      return count + 1;
    }, 0).then(function(count) {
      return console.log("Column media loaded: ", count);
    }).then(callback)["catch"](callback);
  };

  exports.down = function(db, callback) {
    return callback();
  };

}).call(this);
