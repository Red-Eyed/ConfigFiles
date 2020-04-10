function FindProxyForURL(url, host) {
    const proxy = "PROXY ip:port";
    const direct = "DIRECT";

    // If the hostname matches, send direct.
    if (shExpMatch(host, "*.facebook.com") ||
        shExpMatch(host, "*.google.com"))
        return direct;

    // If the protocol or URL matches, send direct.
    if (url.substring(0, 5) == "https:")
        return proxy;

    // If the requested website is hosted within the internal network, send direct.
    if (isPlainHostName(host) ||
        shExpMatch(host, "*.local") ||
        isInNet(dnsResolve(host), "192.168.0.0", "255.255.0.0") ||
        isInNet(dnsResolve(host), "127.0.0.0", "255.255.255.0"))
        return direct;

    // DEFAULT RULE: All other traffic, use below proxies, in fail-over order.
    return proxy;
}