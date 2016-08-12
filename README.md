# ask

## Ngrok container

`docker-compose up` will automatically start an [ngrok container](https://hub.docker.com/r/wernight/ngrok/) and map `web:3000` to a random public subdomain in ngrok.com. To find out the name of that subdomain run `curl localhost:4040/api/tunnels`, or go to `localhost:4040/` to have a nice view of the ngrok container.

Additionally, you can specify one of several environment variable to configure your Ngrok tunnel:

  * `NGROK_AUTH` - Authentication key for your Ngrok account. This is needed for custom subdomains, custom domains, and HTTP authentication.
  * `NGROK_SUBDOMAIN` - Name of the custom subdomain to use for your tunnel. You must also provide the authentication token.
  * `NGROK_DOMAIN` - Paying Ngrok customers can specify a custom domain. Only one subdomain or domain can be specified, with the domain taking priority.
  * `NGROK_USERNAME` - Username to use for HTTP authentication on the tunnel. You must also specify an authentication token.
  * `NGROK_PASSWORD` - Password to use for HTTP authentication on the tunnel. You must also specify an authentication token.
