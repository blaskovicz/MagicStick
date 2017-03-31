var page = require('webpage').create();
var system = require('system');
var fail = function(reason) {
  if (reason.length > 200) {
    reason = reason.substr(0, 200) + '...';
  }
  console.error(reason);
  phantom.exit();
};
var exitTimer = setTimeout(function() {
  fail('timed out');
}, 5000);
if (system.args.length === 1) {
  fail('Usage: phantomjs ' + system.args[0] + ' some-html-uri');
}
var target = system.args[1];

page.open(target, function(status) {
  if (status !== 'success') {
    fail(target + ' could not be reached!');
  }
  var ms = page.evaluate(function() {
    return MagicStick;
  });
  if (
      ms === undefined ||
      typeof ms.Env !== 'object' ||
      typeof ms.Env.RACK_ENV !== 'string' ||
      typeof ms.Env.MAGIC_STICK_VERSION != 'string' ||
      hasEnvPrefix(ms.Env) ||
      hasLeakedSecret(ms.Env)
  ) {
    fail('Expectations not met on MagicStick global => ' + JSON.stringify(ms));
  }

  var scripts = page.evaluate(function() {
    return document.querySelectorAll('script');
  });
  if (
      scripts.length === 0 /* https://github.com/ariya/phantomjs/issues/10652 ||
      missingScriptSrc(scripts) */
  ) {
    fail('Expectations not met on script tags => ' + JSON.stringify(scripts));
  }
  console.log('SUCCESS.')
  phantom.exit();
});

// helper functions
var forObjKV = function(obj, callback) {
  var keys = Object.keys(obj);
  var key;
  var result;
  var i = 0;
  for(; i < keys.length; i++) {
    key = keys[i];
    result = callback(key, obj[key]);
    if (result !== undefined) {
      return result;
    }
  }
};
var missingScriptSrc = function(scripts) {
  var j = 0;
  var script;
  for(; j < scripts.length; j++) {
    if (scripts[j].src === undefined || scripts[j].src === '') {
      return true;
    }
  }
    fail('bye!');
};
var hasEnvPrefix = function(envObj) {
  return forObjKV(envObj, function(k, v) {
    if (k.indexOf('SINATRA_PUBLIC_ENV') !== -1) {
      return true;
    }
  });
};
var hasLeakedSecret = function(envObj) {
  return forObjKV(envObj, function(k, v) {
    if (k.indexOf('SECRET') !== -1) {
      return true;
    }
  });
};
