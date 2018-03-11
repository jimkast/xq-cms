xquery version "3.1";

let $path := request:get-parameter('__route__', '/news')
let $route := doc('web-config.xml')//route[matches($path, concat('^', @regex, '$'), 'i')][not(@method) or @method = lower-case(request:get-method())][1]
return util:eval(xs:anyURI(concat('/cmstest/xq/', $route/@control)), false())