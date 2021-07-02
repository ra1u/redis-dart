Simple test that can be run inside container
we use this for local testing

Requrements:
- docker
- docker-compose

to run this test execute

docker-compose up --abort-on-container-exit && echo ok

In case of funny errors remove pubspec.lock in top dir

Extra:

We also provide script for podman that can be used for rootless execution.
In that case docker is not needed, podman only.

./run_podman.sh
