# btc_wallet

A simple Ruby console tool for interacting with the Bitcoin network.

## Installation - for running directly without Docker

If you want to run `btc_wallet` directly on your system (without Docker), 
you will need to have Ruby and Bundler installed. Then, navigate to the project directory and run:

```bash
bundle install
```

Run tests:
```bash
bundle exec rspec
```

## Usage with Docker Compose

This tool can be easily run using Docker Compose. This method ensures a consistent environment and avoids the need to set up Ruby and dependencies on your local machine.

### Prerequisites

* **Docker:** Make sure you have Docker installed on your system. You can find installation instructions for your operating system on the official Docker website: [https://docs.docker.com/get-docker/](https://docs.docker.com/get-docker/)
* **Docker Compose:** Docker Compose is usually installed along with Docker Desktop. If you installed Docker using other methods, you might need to install Docker Compose separately. Instructions can be found here: [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)

### Files

This project includes two Docker-related files:

* **`Dockerfile`**: This file contains the instructions for building the Docker image for `btc_wallet`.
* **`docker-compose.yml`**: This file defines how to run the `btc_wallet` service using the Docker image.

### Building the Docker Image

1.  Navigate to the root directory of your `btc_wallet` project (the directory containing the `Dockerfile` and `docker-compose.yml` files) in your terminal.
2.  Build the Docker image using the following command:

    ```bash
    docker compose build
    ```

    This command will read the instructions in the `Dockerfile` to create a Docker image named `btc_wallet` (based on the service name in `docker-compose.yml`).

### Running the Tool

Once the image is built, you can run the `btc_wallet` tool using the following command:

```bash
docker-compose run btc_wallet <your_thor_command> <options>
```

* Replace `<your_thor_command>` with the specific command you want to execute in your `btc_wallet` tool (e.g., `create_wallet`, `get_balance`, `send_transaction`).
* Replace `<options>` with any arguments or options that your Thor command accepts (e.g., `--network signet`, `--address <your_address>`).

**Examples:**

* To run the help command of your tool:

```bash
docker-compose run btc_wallet help
```

* To execute a command that interacts with the Signet network:
Get address balance:
```bash
docker-compose run btc_wallet balance

```

To send satoshi to some address:
```bash
docker compose run btc_wallet bundle exec bin/btc_wallet send -a tb1psv6wgyyf226ka8dpsskrjun2kdgnfhhlxdl7l83srzqrh93manwsj3dg26 -m 1300
```  
   

### Optional Volumes

The `docker-compose.yml` file includes an `volumes` section:

```bash
  - btc_wallet_bundle_cache:/usr/local/bundle
  - ./.docker/entrypoints/entrypoint.sh:/entrypoint.sh
  - ./.docker/.bitcoinrb:/app/.bitcoinrb
```

### Optional Environment Variables

The `docker-compose.yml` file also includes an optional `environment` section:

```bash
WALLET_DATA_DIR: /app/.bitcoinrb
WALLET_KEY_FILE: privkey
BITCOIN_NETWORK: signet
LOGGER_LEVEL: error
```

## Usage

```bash
bundle exec bin/btc_wallet help
bundle exec bin/btc_wallet generate
bundle exec bin/btc_wallet balance 
bundle exec bin/btc_wallet send -a tb1psv6wgyyf226ka8dpsskrjun2kdgnfhhlxdl7l83srzqrh93manwsj3dg26 -m 1300 
```

## Contributing

(Optional) If you'd like to contribute to this project, please follow these guidelines:

1.  Fork the repository.
2.  Create a new branch for your feature or bug fix.
3.  Make your changes and commit them.
4.  Push your changes to your fork.
5.  Submit a pull request.

## License

MIT License

Copyright (c) 2025 orphist

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
