xquery version "3.1";

module namespace cms = "cms";

import module namespace request = 'http://exist-db.org/xquery/request';
import module namespace response = 'http://exist-db.org/xquery/response';
import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace util = 'http://exist-db.org/xquery/util';


declare function cms:route() as item()*{
    let $path := request:get-parameter('__route__', '/')
    let $route := doc('/ibe/web-config.xml')//route[matches($path, @regex, 'i')][not(@method) or @method = lower-case(request:get-method())][1]
    return util:eval(xs:anyURI(concat('/ibe/xq/', $route/@control)), false())
};

declare function cms:session() as item()*{
    collection('sessions/')/session[@id = request:get-cookie-value('SESSION')][xs:dateTime(@expires) > current-dateTime()][1]
};

declare function cms:authorized($fn as function(item()) as item()*) as item()*{
    cms:authorized('ANY', $fn)
};

declare function cms:authorized($roles as xs:string*, $fn as function(item()) as item()*) as item()*{
    cms:authorized($roles, $fn, cms:authorized-response#1)
};

declare function cms:authorized-response($session as item()*) as item()*{
    if ($session)
    then cms:html-envelope(function() {cms:page-at('403')})
    else (
        response:set-status-code(302),
        response:set-header('Location', '/login')
    )
};

declare function cms:authorized($roles as xs:string*, $fn as function(item()) as item()*, $unauthorized as function(item()) as item()*) as item()*{
    let $session := cms:session()
    return
        if ($session and ($roles[. = $session/@role] or $roles[. = 'ANY'])) then $fn($session)
        else $unauthorized($session)
};

declare function cms:html-envelope($fn as function(item()) as item()*) as item()*{
    let $ctx := (
        cms:util-request(),
        doc('/ibe/globals.xml')
    )
    return <rsp>{
        $ctx,
        $fn(<rsp>{$ctx}</rsp>)
    }</rsp>
};


declare function cms:page-not-found() as item()*{
    cms:page-at('404')
};

declare function cms:page-at($name as item()*) as item()*{
    doc(concat('/ibe/pages/', $name, '.xml'))/page[1]
};

declare function cms:util-request() as item() {
    <request ip="{request:get-remote-addr()}">{
        <line
        protocol="{request:get-remote-port()}"
        method="{request:get-method()}"
        path="{request:get-parameter('__route__', '/')}"
        query-string="{request:get-query-string()}">
        </line>,
        for $name in request:get-header-names()
        return <header name="{$name}">{request:get-header($name)}</header>,
        <body>{
            for $data in request:get-data()
            return if ($data instance of node()) then $data else util:base64-decode($data)
        }</body>,
        for $param in request:get-parameter-names()
        return for $val in request:get-parameter($param, '')
        return <param name="{$param}">{$val}</param>
    }</request>
};