# iscpp-docker
ISCPP docker configuration

> I am not a docker expert

Please reboot the containers, after first successfull deployment and after an ISCPP update.

## Quick Start

1. Update the .env
2. docker compose up -d --build
3. Open [http://localhost:8080](http://localhost:8080) in your browser.

## Environment Variables (`.env`)

Below are the main variables you can set in your `.env` file:

| Variable                     | Description                                 | Default                |
|------------------------------|---------------------------------------------|------------------------|
| ISCPP_APP_KEY                | Laravel app key                             | (generated if empty) needed for redeployment of an existing database   |
| ISCPP_BRANCH                 | ISCPP Git branch to use                     | main                   |
| ISCPP_USER_DEFAULT_TIMEZONE  | Default user timezone                       | Europe/Berlin          |
| ISCPP_AUTO_UPDATE            | Auto-update app on start (0/1)              | Updates ISCPP on every container start                      |
| ISCPP_CA_IMPORT              | Import custom CA (0/1)                      | Import /docker/ca.crt as a root ca in the image.                      |
| ISCPP_EXPOSE_CONFIG          | Expose config (0/1)                         | 0                      |

**Example `.env`:**

```ini
ISCPP_APP_KEY=

ISCPP_DB_DATABASE=iscpp-db
ISCPP_DB_USERNAME=iscpp-user
ISCPP_APP_URL=http://localhost:8080
ISCPP_APP_PORT=8080
ISCPP_DB_PASSWORD=ThisIsASecretPasswordButYouShouldChangeIt

ISCPP_USER_DEFAULT_TIMEZONE='Europe/Berlin'

ISCPP_BRANCH=docker-support # This will migrate in main soon

```
