# nginx session ticket key rotation
[nginx](http://nginx.org/) session ticket key rotation program for secure
rotation of TLS session ticket keys and sharing in server clusters.

## Usage
You should clone the repository to a place were it can stay. The files are
needed and shouldn't be deleted. The best place is `/etc` as illustrated in the
following example.

```
cd /etc
git clone https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation.git
sh nginx-session-ticket-key-rotation/install.sh example.com localhost
```

### Tests
The repository includes unit tests for all functions and an integration test. To
run the test either execute them separately (have a look at the test directory)
or by issuing `make test`.

You can safely delete the test directory if you don't want to waste disk space.

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
