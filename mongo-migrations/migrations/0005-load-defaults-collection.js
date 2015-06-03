(function() {
  var Promise, dates, defaultColumn, defaultColumnHardware, defaultColumnMedium, defaultPh, mongodb, _;

  mongodb = require('mongodb');

  Promise = require('bluebird');

  _ = require('underscore');

  dates = {
    createdAt: new Date(),
    updatedAt: new Date()
  };

  defaultPh = {
    minimumPhWhenNotRunning: {
      amount: 0,
      unit: "PH"
    },
    maximumPhWhenNotRunning: {
      amount: 14.0,
      unit: "PH"
    },
    minimumPhWhenRunning: {
      amount: 0,
      unit: "PH"
    },
    maximumPhWhenRunning: {
      amount: 14.0,
      unit: "PH"
    }
  };

  defaultColumnMedium = {
    inletPressureLimit: {
      amount: 25.0,
      unit: "MEGAPASCALS"
    },
    inletToOutletPressureLimit: {
      amount: 25,
      unit: "MEGAPASCALS"
    },
    typicalFlowRate: {
      amount: 1,
      unit: "MILLILITERS_PER_MINUTE"
    },
    maximumFlowRate: {
      amount: 1.5,
      unit: "MILLILITERS_PER_MINUTE"
    },
    equivalentColumnVolume: {
      amount: 1.0,
      unit: "MILLILITERS"
    },
    averageParticleDiameter: {
      amount: 10.0,
      unit: "MICROMETERS"
    }
  };

  defaultColumnMedium = _.extend(defaultColumnMedium, defaultPh);

  defaultColumnHardware = {
    internalBedDiameter: {
      amount: 1.0,
      unit: "CENTIMETERS"
    },
    internalBedHeight: {
      amount: 30.0,
      unit: "CENTIMETERS"
    },
    internalVolume: {
      amount: 10,
      unit: "MILLILITERS"
    },
    maximumWorkingPressure: {
      amount: 25.0,
      unit: "MEGAPASCALS"
    }
  };

  defaultColumnHardware = _.extend(defaultColumnHardware, defaultPh);

  defaultColumn = {
    inletPressureLimit: {
      amount: 5.0,
      unit: "MEGAPASCALS"
    },
    inletToOutletPressureLimit: {
      amount: 1.8,
      unit: "MEGAPASCALS"
    },
    columnVolumeSize: {
      amount: 7.2,
      unit: "MILLILITERS"
    },
    maximumFlowRate: {
      amount: 1.5,
      unit: "MILLILITERS_PER_MINUTE"
    }
  };

  exports.up = function(db, next) {
    var columnHardwareDb, columnMediaDb, columnsDb, manufacturersDb;
    manufacturersDb = mongodb.Collection(db, 'manufacturers');
    columnMediaDb = mongodb.Collection(db, 'columnMedia');
    columnHardwareDb = mongodb.Collection(db, 'columnHardware');
    columnsDb = mongodb.Collection(db, 'columns');
    Promise.promisifyAll(manufacturersDb);
    Promise.promisifyAll(columnMediaDb);
    Promise.promisifyAll(columnHardwareDb);
    Promise.promisifyAll(columnsDb);
    return manufacturersDb.insertAsync({
      _id: 1,
      name: "GE Biosciences",
      dates: dates
    }).then(function() {
      return manufacturersDb.insertAsync({
        _id: 2,
        name: "Bio-Rad",
        dates: dates
      });
    }).then(function() {
      return manufacturersDb.insertAsync({
        _id: 3,
        name: "Clontech Laboratories",
        dates: dates
      });
    }).then(function() {
      var columnMedia;
      columnMedia = {
        _id: 1,
        manufacturer_id: 1,
        name: "Custom",
        description: "",
        isEnabled: "ENABLED",
        properties: defaultColumnMedium,
        dates: dates
      };
      return columnMediaDb.insertAsync(columnMedia);
    }).then(function() {
      var columnHardware;
      columnHardware = {
        _id: 1,
        manufacturer_id: 1,
        name: "Custom",
        description: "",
        isEnabled: "ENABLED",
        properties: defaultColumnHardware,
        dates: dates
      };
      return columnHardwareDb.insertAsync(columnHardware);
    }).then(function() {
      var column;
      column = {
        _id: 1,
        name: "Custom",
        description: "",
        isEnabled: "ENABLED",
        technique: "GEL_FILTRATION",
        manufacturer_id: 1,
        columnMedia_id: 1,
        columnHardware_id: 1,
        properties: defaultColumn,
        dates: dates
      };
      return columnsDb.insertAsync(column);
    }).then(function() {
      return next();
    })["catch"](next);
  };

  exports.down = function(db, next) {
    return next();
  };

}).call(this);
