# nginx session ticket key rotation
[nginx](http://nginx.org/) session ticket key rotation program for secure
rotation of TLS session ticket keys and sharing in server clusters.

This program was developed as part of my Master's thesis at the
[Fachhochschule Salzburg](https://github.com/fh-salzburg). I hope to release my
thesis with an open license as soon as possible. You'll find much more details
on TLS, its performance, and this program in there. Although I aim to provide a
complete documentation for it here, I currently don't have the time to write it
up because (you guessed) I'm working on the thesis. Feel free to open an issue
if you have questions or found a bug.

## Usage
You should clone the repository to a place were it can stay. The files are
needed and shouldn't be deleted. The best place is `/etc` as illustrated in the
following example.

```
cd /etc
git clone https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation.git
sh nginx-session-ticket-key-rotation/install.sh example.com localhost
```

This would install TLS session ticket rotation for `example.com` and `localhost`.
You have to edit your nginx configuration yourself afterwards, a minimal
configuration with the default ticket lifetime of my installation for `localhost`
would look like the following example.

```
http {
  server {
    listen                     443 ssl;
    server_name                localhost;
    ssl_certificate            cert.pem;
    ssl_certificate_key        cert.key;
    ssl_ciphers                HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers  on;
    ssl_session_timeout        36h;
    ssl_session_ticket_key     /mnt/session_ticket_keys/localhost.1.key;
    ssl_session_ticket_key     /mnt/session_ticket_keys/localhost.2.key;
    ssl_session_ticket_key     /mnt/session_ticket_keys/localhost.3.key;
  }
}
```

To uninstall the rotation mechanism simply execute the `uninstall.sh` script.

```
sh nginx-session-ticket-key-rotation/uninstall.sh
```

### Server Names
You have to supply the server names (domains) to the installation script, this
is important because you should only use a ticket key on a per host basis.
You'll open your servers to various attacks (e.g. [5](#references)) if you share
a keys among several hosts. The server names are also used to generate the key
file names, which makes it easier for you to know which ticket belongs to which
server.

*Note* that there are situations where you want to share keys among several
hosts. But I warned you, this is something that you should only attempt if you
absolutely understand the potential risks and what it can be good for!

### Tests
The repository includes unit tests for most functions and an integration test.
To run the test either execute them separately (have a look at the test
directory) or by issuing `make test`.

You can safely delete the test directory if you don't want to waste disk space.

### Coding Standard
The program should be as POSIX compliant as possible and everything was tested
with the dash interpreter. Note that I prefer to use quotes around most strings
because developers are used to do so in almost all other languages. Also note
that there is a special dash bug related to closing `stdout` which is why I had
to redirect `stdout` to `/dev/null` instead of directly closing it. The return
values are always documented for each function, often that returned value is
implicit returned by another called function. So you won't find a `return`
statement in each function.

The best place for information on POSIX is [The Open Group Base Specifications]
(http://pubs.opengroup.org/onlinepubs/9699919799/nframe.html).

### TODO
- Better error handling with a proper exit handler instead of `set -e` that
  gives a hint what actually went wrong.
- Unit tests with [shUnit2](https://code.google.com/p/shunit2/).
- Tell users to install something for better random numbers (esp. VPS), see
  [Havege](https://www.irisa.fr/caps/projects/hipsor/)
  ([`haveged`](https://packages.debian.org/wheezy/haveged)).
- Tell users to test their random numbers
  ([`rngtest`](https://github.com/waitman/rngtest))?
- Create slave program for clusters.
- Install ntp daemon right away if none was found?
- Test with other operating systems (currently only Debian tested).

## License
> This is free and unencumbered software released into the public domain.
>
> For more information, please refer to <http://unlicense.org>

## References
1. Joseph Salowey, Harry Zhou, Pasi Eronen and Hannes Tschofenig:
  “[RFC 5077](https://tools.ietf.org/html/rfc5077)”, January, 2008.
2. Jacob Hoffman-Andrews: “[Forward Secrecy at Twitter]
   (https://blog.twitter.com/2013/forward-secrecy-at-twitter)”, November 22th, 2013.
3. Adam Langley: “[How to botch TLS forward secrecy]
   (https://www.imperialviolet.org/2013/06/27/botchingpfs.html)”, July 27th, 2013.
4. Jacob Hoffman-Andrews: “[How to check for TLS ticket key rotation]
   (https://jacob.hoffman-andrews.com/README/how-to-check-for-tls-ticket-key-rotation/)”, December 5th, 2013.
5. Antoine Delignat-Lavaud and Karthikeyan Bhargavan:
   “[Virtual Host Confusion: Weaknesses and Exploits]
   (https://www.blackhat.com/docs/us-14/materials/us-14-Delignat-The-BEAST-Wins-Again-Why-TLS-Keeps-Failing-To-Protect-HTTP-wp.pdf)”, August, 2014.

## Weblinks
Other repositories of interest:
- [nginx-configuration](https://github.com/Fleshgrinder/nginx-configuration)
- [nginx-compile](https://github.com/Fleshgrinder/nginx-compile)
- [nginx-sysvinit-script](https://github.com/Fleshgrinder/nginx-sysvinit-script)
