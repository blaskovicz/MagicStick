// inlined from https://github.com/auth0/jwt-decode
//
"use strict";
function InvalidTokenError(message) {
  this.name = "InvalidTokenError";
  this.message = message || "Invalid token specified";
  this.stack = new Error().stack;
}
InvalidTokenError.prototype = Object.create(Error.prototype);
InvalidTokenError.prototype.constructor = InvalidTokenError;

function b64DecodeUnicode(str) {
  return decodeURIComponent(
    atob(str).replace(/(.)/g, function(m, p) {
      var code = p
        .charCodeAt(0)
        .toString(16)
        .toUpperCase();
      if (code.length < 2) {
        code = "0" + code;
      }
      return "%" + code;
    })
  );
}

export function base64_url_decode(str) {
  var output = str.replace(/-/g, "+").replace(/_/g, "/");
  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += "==";
      break;
    case 3:
      output += "=";
      break;
    default:
      throw "Illegal base64url string!";
  }

  try {
    return b64DecodeUnicode(output);
  } catch (err) {
    return atob(output);
  }
}

export function jwt_decode(token, options) {
  if (typeof token !== "string")
    throw new InvalidTokenError("token must be a string");

  options = options || {};
  var pos = options.header === true ? 0 : 1;
  try {
    return JSON.parse(base64_url_decode(token.split(".")[pos]));
  } catch (e) {
    throw new InvalidTokenError(e);
  }
}
