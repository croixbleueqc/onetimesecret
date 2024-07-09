# Onetime Secret - v0.15.0

*Keep passwords and other sensitive information out of your inboxes and chat logs.*

### Latest releases

* **Ruby 3+ (recommended): [latest](https://github.com/onetimesecret/onetimesecret/releases/latest)**
* Ruby 2.7, 2.6: [v0.12.1](https://github.com/onetimesecret/onetimesecret/releases/tag/v0.12.1)

---


## What is a Onetime Secret?

A onetime secret is a link that can be viewed only once. A single-use URL.

Try it out on <a class="msg" href="https://onetimesecret.com/">OnetimeSecret.com</a>!


### Why would I want to use it?

When you send people sensitive info like passwords and private links via email or chat, there are copies of that information stored in many places. If you use a one-time link instead, the information persists for a single viewing which means it can't be read by someone else later. This allows you to send sensitive information in a safe way knowing it's seen by one person only. Think of it like a self-destructing message.


## Installation

### System Requirements

* Any recent linux disto (we use debian) or *BSD
* System dependencies:
  * Ruby 3.2, 3.1, 3.0, 2.7.8
  * Redis server 5+
* Minimum specs:
  * 2 core CPU (or equivalent)
  * 1GB memory
  * 4GB disk


### Docker

Building and running locally.

```bash
  # Create or update the image tagged 'onetimesecret'
  $ docker build -t onetimesecret .
  ...

  # Start redis container
  $ docker run -p 6379:6379 -d redis:bookworm

  # Set essential environment variables
  HOST=localhost:3000
  SSL=false
  COLONEL=admin@example.com
  REDIS_URL=redis://host.docker.internal:6379/0

  # Create and run a container named `onetimesecret`
  $ docker run -p 3000:3000 -d --name onetimesecret \
      -e REDIS_URL=$REDIS_URL \
      -e COLONEL=$COLONEL \
      -e HOST=$HOST \
      -e SSL=$SSL \
      onetimesecret/onetimesecret:latest
```

#### Multi-platform builds

Docker's buildx command is a powerful tool that allows you to create Docker images for multiple platforms simultaneously. Use buildx to build a Docker image that can run on both amd64 (standard Intel/AMD CPUs) and arm64 (ARM CPUs, like those in the Apple M1 chip) platforms.

```bash
  $ docker buildx build --platform=linux/amd64,linux/arm64 . -t onetimesecret:latest
```

#### "The container name "/onetimesecret" is already in use"

```bash
  # If the container already exists, you can simply start it again:
  $ docker start onetimesecret

  # OR, remove the existing container
  $ docker rm onetimesecret
```

After the container has been removed, the regular `docker run` command will work again.

##### [Croix-Bleue Docker Hub](https://hub.docker.com/r/onetimesecret/onetimesecret)

```bash
docker build -t croixbleueqc/ots -f devops/Dockerfile .
````

```bash
  $ docker run -p 6379:6379 --name redis -d redis
  $ REDIS_URL="redis://172.17.0.2:6379/0"

  $ docker pull croixbleueqc/onetimesecret:latest
  $ docker run -p 3000:3000 -d --name onetimesecret \
    -e REDIS_URL=$REDIS_URL \
    croixbleueqc/onetimesecret:latest
```

### Docker Compose

See the dedicated [Docker Compose repo](https://github.com/onetimesecret/docker-compose/).


### Manually

Get the code, one of:

* Download the [latest release](https://github.com/onetimesecret/onetimesecret/archive/refs/tags/latest.tar.gz)

* Clone this repo:

```bash
  $ git clone https://github.com/onetimesecret/onetimesecret.git
```

### For a fresh install

If you're installing on a fresh system, you'll need to install a few system dependencies before you can run the webapp.

#### 0. Install system dependencies

The official Ruby docs have a great guide on [installing Ruby](https://www.ruby-lang.org/en/documentation/installation/). Here's a quick guide for Debian/Ubuntu:


For Debian / Ubuntu:

```bash

  # Make sure you have the latest packages (even if you're on a fresh install)
  $ sudo apt update

  # Install the basic tools of life
  $ sudo apt install -y git curl sudo

  # Install Ruby (3) and Redis
  $ sudo apt install -y ruby-full redis-server
```

NOTE: The redis-server service should start automatically after installing it. You can check that it's up by running: `service redis-server status`. If it's not running, you can start it with `service redis-server start`.

#### 1. Now get the code via git:

```bash
  $ git clone https://github.com/onetimesecret/onetimesecret.git
```


#### 2. Copy the configuration files into place and modify as needed:

```bash
  $ cd onetimesecret

  $ cp --preserve --no-clobber ./etc/config.example ./etc/config
  $ cp --preserve --no-clobber .env.example .env
```


#### 3. Install ruby dependencies

```bash

  # We use bundler manage the rest of the ruby dependencies
  $ sudo gem install bundler

  # Install the rubygems listing inthe Gemfile
  $ bundle install
```

#### 4. Run the webapp

```bash
  $ bundle exec thin -R config.ru -p 3000 start

  ---  ONETIME app v0.13  -----------------------------------
  Config: /Users/d/Projects/opensource/onetimesecret/etc/config
  2024-04-10 22:39:15 -0700 Thin web server (v1.8.2 codename Ruby Razor)
  2024-04-10 22:39:15 -0700 Maximum connections set to 1024
  2024-04-10 22:39:15 -0700 Listening on 0.0.0.0:3000, CTRL+C to stop
```

See the [Ruby CI workflow](.github/workflows/ruby.yaml) for another example of the steps.


## Debugging

To run in debug mode set `ONETIME_DEBUG=true`.

```bash
  $ ONETIME_DEBUG=true bundle exec thin -e dev start`
```

If you're having trouble cloning via SSH, you can double check your SSH config like this:

**With a github account**
```bash
  ssh -T git@github.com
  Hi delano! You've successfully authenticated, but GitHub does not provide shell access.
```

**Without a github account**
```bash
  ssh -T git@github.com
  Warning: Permanently added the RSA host key for IP address '0.0.0.0/0' to the list of known hosts.
  git@github.com: Permission denied (publickey).
```

*NOTE: you can also use the etc directory from here instead of copying it to the system. Just be sure to secure the permissions on it*

```bash
  chown -R ots ./etc
  chmod -R o-rwx ./etc
```

### Configuration

1. `./etc/config`
  * Update your secret key
    * Back up your secret key (e.g. in your password manager). If you lose it, you won't be able to decrypt any existing secrets.
  * Update the SMTP or SendGrid credentials for email sending
    * Update the from address (it's used for all sent emails)
  * Update the rate limits at the bottom of the file
    * The numbers refer to the number of times each action can occur for unauthenticated users.
  * Enable or disable the available locales.
1. `./etc/redis.conf`
  * The host, port, and password need to match
1. `/etc/onetime/locale/*`
  * Optionally you can customize the text used throughout the site and emails
  * You can also edit the `:broadcast` string to display a brief message at the top of every page

### Running

There are many ways to run the webapp. The default web server we use is [thin](https://github.com/macournoyer/thin). It's a Rack app so any server in the ruby ecosystem that supports Rack apps will work.

**To run locally:**

```bash
  bundle exec thin -e dev -R config.ru -p 3000 start
```

**To run on a server:**

```bash
  bundle exec thin -d -S /var/run/thin/thin.sock -l /var/log/thin/thin.log -P /var/run/thin/thin.pid -e prod -s 2 restart
```


## Generating a global secret

We include a global secret in the encryption key so it needs to be long and secure. One approach for generating a secret:

```bash
  dd if=/dev/urandom bs=20 count=1 | openssl sha256
```
