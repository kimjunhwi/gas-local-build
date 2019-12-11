"use strict";


var assert = require('assert');
var gas = require('.././index.js');
//disable log to console for clean test output
gas.globalMockDefault.Logger.enabled = false;

describe('Custom mock of services', function () {
  //default mock object
  var defMock = gas.globalMockDefault;
  //extend default mock object
  var customMock = { MailApp: { getRemainingDailyQuota: function () { return 50; } }, __proto__: defMock };
  //pass it to require
  var m = gas.require('./test/src', customMock);

  it('mock additional service - MailApp', function () {
    //Contains call to MailApp. if no exception then MailApp is mocked as it should. 
    var q = m.Utils.getRemainingEmailQuota();
    //but assert returned value also for 100% sure :)
    assert(q == 50);
  })

  it('default Logger is mocked also', function () {
    //Contains call to Logger. if no exception then Logger is mocked as it should. test passes 
    m.Utils.logCurrentDateTime();
  })
});
