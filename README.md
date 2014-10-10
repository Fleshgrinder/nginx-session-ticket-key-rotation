# nginx TLS session ticket key rotation
[nginx](http://nginx.org/) TLS session ticket key rotation script collection for
secure rotation of keys and sharing in server clusters.

## Usage
```
git clone https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation.git
sh nginx-session-ticket-key-rotation/install.sh example.com localhost
```

## License
> This is free and unencumbered software released into the public domain.
>
> For more information, please refer to <http://unlicense.org>

## References
- Joseph Salowey, Harry Zhou, Pasi Eronen and Hannes Tschofenig: “[RFC 5077](https://tools.ietf.org/html/rfc5077)”, January, 2008.
- Jacob Hoffman-Andrews: “[Forward Secrecy at Twitter](https://blog.twitter.com/2013/forward-secrecy-at-twitter)”, November 22th, 2013.
- Adam Langley: “[How to botch TLS forward secrecy](https://www.imperialviolet.org/2013/06/27/botchingpfs.html)”, July 27th, 2013.
- Jacob Hoffman-Andrews: “[How to check for TLS ticket key rotation](https://jacob.hoffman-andrews.com/README/how-to-check-for-tls-ticket-key-rotation/)”, December 5th, 2013.

## Weblinks
Other repositories of interest:
- [nginx-configuration](https://github.com/Fleshgrinder/nginx-configuration)
- [nginx-compile](https://github.com/Fleshgrinder/nginx-compile)
- [nginx-sysvinit-script](https://github.com/Fleshgrinder/nginx-sysvinit-script)
