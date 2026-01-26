function FindProxyForURL(url, host) {
    // Convert to lowercase for case-insensitive matching
    host = host.toLowerCase();
    url = url.toLowerCase();
    
	if (host == "hrsuappba7003" || // Exact hostname match for internal server
		shExpMatch(host, "*.acsgs.com") || // Domain-based matches
        shExpMatch(host, "*.int.benefitcenter.com") || 
        shExpMatch(host, "*.securep.benefitcenter.com")) {
        return "PROXY conduent-pos:8888";
    }
    
    // Direct connection for everything else
    return "DIRECT";
}