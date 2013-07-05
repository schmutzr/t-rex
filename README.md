T_Rex
=====

A ruby-class and test script to transform list of strings to (exact) /RE/s

* "working" branch: old uncompressed tree nodes (ie, each node equals one token/character)
* "compact" branch: new compressed tree format

* Usage:
    # initialize
    tree = T_rex.new # note, the root is anonymous to allow top-level alternatives
    
    # fill tree
    tree.add_child "/authservice-ldap-postextern"
    ...
    tree.add_child "/authservice-radius-pext/css"
    
    # query tree (optional :) )
    tree.member? "/authservice-radius-pext/css" # -> true|false
    tree.lookup  "/authservice-radius-pext/css" # -> instance|false
    
    # generate output (strings)
    puts tree.to_re # regular expression, eg: (not yet tail-compressed)
    
    puts tree.to_dot # and use dot to render the tree (debug mainly)


---

* Turns this:
    /
    /qos
    /errordocuments
    /authservice-certificate
    /authservice-eaas
    /authservice-eaas-pext
    /authservice-ldap
    /authservice-ldap-employeeID
    /authservice-ldap-postextern
    /authservice-radius
    /authservice-radius/css
    /authservice-radius/css/images
    /authservice-radius/script
    /authservice-radius-eaas
    /authservice-radius-eaas/css
    /authservice-radius-eaas/css/images
    /authservice-radius-eaas/images
    /authservice-radius-eaas/script
    /authservice-radius-eaas-weakpost
    /authservice-radius-pext
    /authservice-radius-pext/images
    /authservice-radius-pext/css
    /authservice-radius-pext/css/images
    /authservice-radius-pext/script
    /authservice-fakelogin
    /authservice-spnego
    /authservice-portal
    /authservice-changepassword
    /authservice-changepassword-pext

* via this:
    <img src="">renodes.svg</img>

* into this:
    /(qos|errordocuments|authservice-(c(ertificate|hangepassword(-pext)?)|eaas(-pext)?|ldap(-(employeeID|postextern))?|radius(/(css(/images)?|script)|-(eaas(/(css(/images)?|images|script)|-weakpost)?|pext(/(images|css(/images)?|script))?))?|fakelogin|spnego|portal))?/?(.*.css|.*.gif|.*.html|.*.png|c(hangeLanguage.do|onsole)|favicon.ico|h(eartbeat.html|ome.do)|index(.do|_strong.do)|j_spring_cas_security_check|log(in|out(Portal(.do)?)?)|post-sys-status|robots.txt|samlValidate|viewer)
