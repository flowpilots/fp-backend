(function() {
  var key, val, _ref;

  // Switch to coffee-script!
  require('coffee-script');

  _ref = require('./backend');
  for (key in _ref) {
    val = _ref[key];
    exports[key] = val;
  }
}).call(this);
