# iscpp-docker
ISCPP docker configuration

> I am not a docker expert

Please reboot the containers, after first successfull deployment and after an ISCPP update.

## Quick Start

1. Update docker-compose.yml
2. docker compose up -d
3. Open [http://localhost:8880](http://localhost:8880) in your browser.

## Behind a reverse proxy

ISCPP takes its public address from the `X-Forwarded-*` headers of the proxy in front
of the stack. If the proxy does not send them, ISCPP only sees the internal address
(e.g. `localhost:8880`) and redirects the browser there, for example after the login.

Example for nginx as the public reverse proxy (this is your own proxy in front of the
stack, not `nginx/default.conf`, which needs no changes):

```nginx
location / {
    proxy_pass http://127.0.0.1:8880;
    proxy_set_header Host              $host;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host  $host;
    proxy_set_header X-Forwarded-Port  $server_port;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

Also set `APP_URL` in `docker-compose.yml` to the public address (e.g.
`https://iscpp.example.com`). It is used wherever there is no request, such as links
in notifications sent by the worker or the scheduler.
