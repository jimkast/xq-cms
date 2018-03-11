xquery version "3.1";

module namespace cmsauth = "auth";

import module namespace cms = 'cms' at '/ibe/xqlib/cms.xq';
import module namespace request = 'http://exist-db.org/xquery/request';
import module namespace response = 'http://exist-db.org/xquery/response';
import module namespace xmldb = 'http://exist-db.org/xquery/xmldb';
import module namespace util = 'http://exist-db.org/xquery/util';


declare function cmsauth:session() as item()*{
    collection('../sessions/')/session[@id = request:get-cookie-value('SESSION')][xs:dateTime(@expires) > current-dateTime()][1]
};

declare function cmsauth:authorized($fn as function(item()) as item()*) as item()*{
    cmsauth:authorized('ANY', $fn)
};

declare function cmsauth:authorized($roles as xs:string*, $fn as function(item()) as item()*) as item()*{
    cmsauth:authorized($roles, $fn, cms:authorized-response#1)
};

declare function cmsauth:authorized-response($session as item()*) as item()*{
    if ($session)
    then cms:html-envelope(function() {cms:page-at('403')})
    else (
        response:set-status-code(302),
        response:set-header('Location', '/login')
    )
};

declare function cmsauth:authorized($roles as xs:string*, $fn as function(item()) as item()*, $unauthorized as function(item()) as item()*) as item()*{
    let $session := cmsauth:session()
    return
        if ($session and ($roles[. = $session/@role] or $roles[. = 'ANY'])) then $fn($session)
        else $unauthorized($session)
};
