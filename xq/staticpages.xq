xquery version "3.1";

import module namespace cms = 'cms' at '../xqlib/cms.xq';

cms:html-envelope(
    function($ctx){
        cms:page-at('static'),
        let $page := collection('/cmstest/staticpages')/article[@url = $ctx/request/line/@path]
        return if ($page) then $page else cms:page-not-found()
    }
)