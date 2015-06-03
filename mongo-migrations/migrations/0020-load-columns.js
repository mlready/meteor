(function() {
  var Promise, buildColumnParameters, buildColumns, columnHardwareKeys, columnMediaKeys, dates, fs, loadColumnHardwareKeys, loadColumnMediaKeys, mongodb, parseXml, parser, xml2js, _;

  Promise = require('bluebird');

  fs = require('fs');

  mongodb = require('mongodb');

  xml2js = require('xml2js');

  _ = require('underscore');

  parser = new xml2js.Parser();

  columnMediaKeys = {};

  columnHardwareKeys = {};

  dates = {
    createdAt: new Date(),
    updatedAt: new Date()
  };

  loadColumnMediaKeys = function(results) {
    return results.forEach(function(result) {
      var column_media_name, id;
      id = result._id;
      column_media_name = result.name;
      return columnMediaKeys[column_media_name] = id;
    });
  };

  loadColumnHardwareKeys = function(results) {
    return results.forEach(function(result) {
      var column_hardware_name, id;
      id = result._id;
      column_hardware_name = result.name;
      return columnHardwareKeys[column_hardware_name] = id;
    });
  };

  buildColumnParameters = function(properties) {
    var columnParameters;
    columnParameters = {
      inletPressureLimit: {
        amount: properties.inletPressureLimit,
        unit: "MEGAPASCALS"
      },
      inletToOutletPressureLimit: {
        amount: properties.inletToOutletPressureLimit,
        unit: "MEGAPASCALS"
      },
      columnVolumeSize: {
        amount: properties.columnVolumeSize,
        unit: "MILLILITERS"
      },
      maximumFlowRate: {
        amount: properties.maximumFlowRate,
        unit: "MILLILITERS_PER_MINUTE"
      }
    };
    return columnParameters;
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

  buildColumns = function(columnTypes) {
    var bedDiameterInCentimeters, bedHeightInCentimeters, calculatedVolumeInMilliliters, columnDescription, columnMaximumFlowrateInMillilitersPerMinute, columnName, columnProperties, columnType, column_hardware_id, column_media_id, columnsToInsert, defaultFlowRateInMillilitersPerMinute, deltaColumnPressureInMegaPascals, hardware, hardwareName, media, mediaName, preColumnPressureInMegaPascals, technique, techniqueType, totalLiquidVolumeInMilliliters, voidVolumeInMilliliters, _i, _len;
    columnsToInsert = [];
    for (_i = 0, _len = columnTypes.length; _i < _len; _i++) {
      columnType = columnTypes[_i];
      media = columnType.Media[0];
      mediaName = media.Name[0].trim();
      hardware = columnType.Hardware[0];
      hardwareName = hardware.Name[0].trim();
      defaultFlowRateInMillilitersPerMinute = parseFloat(columnType.DefaultFlowrate[0]);
      technique = media.TechniqueName[0].trim();
      columnDescription = "" + hardwareName + " - " + mediaName;
      columnName = columnType.Name[0].trim();
      columnMaximumFlowrateInMillilitersPerMinute = parseFloat(columnType.MaxFlowrate[0]);
      deltaColumnPressureInMegaPascals = parseFloat(columnType.DeltaColumnPressure[0]);
      preColumnPressureInMegaPascals = parseFloat(hardware.PreColumnPressure[0]);
      totalLiquidVolumeInMilliliters = null;
      if (columnType.TotalLiquidVolume != null) {
        totalLiquidVolumeInMilliliters = parseFloat(columnType.TotalLiquidVolume[0]);
      }
      voidVolumeInMilliliters = null;
      if (columnType.VoidVolume != null) {
        voidVolumeInMilliliters = parseFloat(columnType.VoidVolume[0]);
      }
      bedDiameterInCentimeters = parseFloat(hardware.Diameter);
      bedHeightInCentimeters = parseFloat(columnType.BedHeight);
      calculatedVolumeInMilliliters = bedHeightInCentimeters * Math.pow(bedDiameterInCentimeters / 2, 2) * Math.PI;
      if ((totalLiquidVolumeInMilliliters != null) && (voidVolumeInMilliliters == null)) {
        if (totalLiquidVolumeInMilliliters > calculatedVolumeInMilliliters) {
          continue;
        }
      }
      if (voidVolumeInMilliliters == null) {
        voidVolumeInMilliliters = totalLiquidVolumeInMilliliters;
      }
      techniqueType = null;
      switch (technique) {
        case "AnionExchange":
          techniqueType = "ANION_EXCHANGE";
          break;
        case "CationExchange":
          techniqueType = "CATION_EXCHANGE";
          break;
        case "HIC":
          techniqueType = "HIC";
          break;
        case "Affinity":
          techniqueType = "AFFINITY";
          break;
        case "GelFiltration":
          techniqueType = "GEL_FILTRATION";
          break;
        case "Desalting":
          techniqueType = "DESALTING";
          break;
        case "Any":
          techniqueType = "MULTIPLE_TECHNIQUES";
          break;
        default:
          continue;
      }
      columnProperties = buildColumnParameters({
        inletPressureLimit: preColumnPressureInMegaPascals,
        inletToOutletPressureLimit: deltaColumnPressureInMegaPascals,
        columnVolumeSize: parseFloat(voidVolumeInMilliliters),
        maximumFlowRate: columnMaximumFlowrateInMillilitersPerMinute
      });
      column_media_id = columnMediaKeys[mediaName];
      column_hardware_id = columnHardwareKeys[hardwareName];
      columnsToInsert.push({
        columnName: columnName,
        column_media_id: column_media_id,
        column_hardware_id: column_hardware_id,
        columnDescription: columnDescription,
        columnProperties: columnProperties,
        techniqueType: techniqueType
      });
    }
    return columnsToInsert;
  };

  exports.up = function(db, callback) {
    var Collection, columnHardwareDb, columnMediaDb, columnsDb;
    Collection = mongodb.Collection;
    Promise.promisifyAll(Collection.prototype);
    columnsDb = Collection(db, 'columns');
    columnHardwareDb = Collection(db, 'columnHardware');
    columnMediaDb = Collection(db, 'columnMedia');
    fs = Promise.promisifyAll(fs);
    Collection.prototype._find = Collection.prototype.find;
    Collection.prototype.find = function() {
      var cursor;
      cursor = this._find.apply(this, arguments);
      Promise.promisifyAll(cursor);
      return cursor;
    };
    return columnMediaDb.find({}, {
      _id: true,
      name: true
    }).toArrayAsync().then(loadColumnMediaKeys).then(function() {
      return columnHardwareDb.find({}, {
        _id: true,
        name: true
      }).toArrayAsync();
    }).then(loadColumnHardwareKeys).then(function() {
      return fs.readFileAsync('assets/import-column-types.xml');
    }).then(parseXml).then(buildColumns).map(function(result) {
      var column, columnDescription, columnName, columnProperties, column_hardware_id, column_media_id, techniqueType;
      columnName = result.columnName, column_media_id = result.column_media_id, column_hardware_id = result.column_hardware_id, columnDescription = result.columnDescription, columnProperties = result.columnProperties, techniqueType = result.techniqueType;
      column = {
        name: columnName.trim(),
        technique: techniqueType.trim(),
        isEnabled: "ENABLED",
        manufacturer_id: 1,
        columnMedia_id: column_media_id,
        columnHardware_id: column_hardware_id,
        description: columnDescription.trim(),
        properties: columnProperties,
        dates: dates
      };
      return columnsDb.insertAsync(column);
    }).reduce(function(count, updateResult) {
      return count + 1;
    }, 0).then(function(count) {
      return console.log("Columns loaded: ", count);
    }).then(callback)["catch"](callback);
  };

  exports.down = function(db, callback) {
    return callback();
  };

}).call(this);
