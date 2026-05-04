import Foundation

// JS prelude evaluated once at config load. Provides:
//   - A minimal URL polyfill (RFC 3986 regex parser)
//   - Helper functions that return marker objects compiled by Swift to native code
//   - CommonJS module scaffolding
//
// Everything here is engineered for a single goal: keep the hot path in Swift.
// Helpers return DATA (marker objects), not functions, so the engine compiles
// them to NSRegularExpression / Set<String> / etc. at config load time. Bridge
// crossings on the hot path are only paid for user-written `(url, ctx) => ...`
// predicates.

let JS_PRELUDE = """
// ---------- URL polyfill (lazy searchParams, no DOM, no IDNA) ----------
(function(g) {
  if (g.URL) return;
  function URL(href) {
    var m = /^([a-z][a-z0-9+.-]*:)(?:\\/\\/(?:([^:@\\/]*)(?::([^@\\/]*))?@)?([^:\\/?#]*)(?::(\\d+))?)?([^?#]*)(\\?[^#]*)?(#.*)?$/i.exec(href);
    if (!m) throw new TypeError("Invalid URL: " + href);
    this.href = href;
    this.protocol = m[1];
    this.username = m[2] || "";
    this.password = m[3] || "";
    this.hostname = m[4] || "";
    this.port = m[5] || "";
    this.host = this.hostname + (this.port ? ":" + this.port : "");
    this.pathname = m[6] || "";
    this.search = m[7] || "";
    this.hash = m[8] || "";
    var sp = null;
    var self = this;
    Object.defineProperty(this, "searchParams", { get: function() {
      if (sp) return sp;
      sp = { _m: {},
        get: function(k) { return this._m[k] ? this._m[k][0] : null; },
        getAll: function(k) { return this._m[k] || []; },
        has: function(k) { return !!this._m[k]; },
        set: function(k, v) { this._m[k] = [String(v)]; },
        append: function(k, v) { (this._m[k] = this._m[k] || []).push(String(v)); },
        delete: function(k) { delete this._m[k]; },
        toString: function() { var p=[],k,i; for(k in this._m) for(i=0;i<this._m[k].length;i++) p.push(encodeURIComponent(k)+"="+encodeURIComponent(this._m[k][i])); return p.join("&"); }
      };
      if (self.search.length > 1) {
        var pairs = self.search.slice(1).split("&");
        for (var i=0;i<pairs.length;i++) {
          if (!pairs[i]) continue;
          var kv = pairs[i].split("=");
          sp.append(decodeURIComponent(kv[0]), kv[1] ? decodeURIComponent(kv[1].replace(/\\+/g, ' ')) : "");
        }
      }
      return sp;
    }});
  }
  g.URL = URL;
})(this);

// ---------- Marker-returning helpers (compiled to native by Swift) ----------

// Match URLs whose hostname is one of the given hosts, or a subdomain thereof.
//   domain("github.com")           → matches github.com, *.github.com
//   domain("a.com", "b.com")       → matches either
function domain() {
  var hosts = [];
  for (var i = 0; i < arguments.length; i++) hosts.push(String(arguments[i]).toLowerCase());
  return { __type: "domain", hosts: hosts };
}

// Match when the calling app is one of these bundle IDs.
//   from("com.tinyspeck.slackmacgap")
function from() {
  var apps = [];
  for (var i = 0; i < arguments.length; i++) apps.push(String(arguments[i]));
  return { __type: "from", apps: apps };
}

// Match when any of these apps is currently running.
//   running("us.zoom.xos")
function running() {
  var apps = [];
  for (var i = 0; i < arguments.length; i++) apps.push(String(arguments[i]));
  return { __type: "running", apps: apps };
}

// Rewrite that strips the named query params. Supports trailing * for prefix.
//   strip("utm_source", "fbclid")
//   strip("utm_*")                    → strips utm_source, utm_medium, ...
function strip() {
  var params = [];
  for (var i = 0; i < arguments.length; i++) params.push(String(arguments[i]));
  return { __type: "strip", params: params };
}

// ---------- CommonJS scaffolding ----------
var __finchModule = { exports: {} };
"""

// Wrap user source so module/exports are scoped locally and don't pollute globals.
func wrapUserConfig(_ src: String) -> String {
    return "(function(module, exports) {\n\(src)\n})(__finchModule, __finchModule.exports);"
}
