Simple test that can be run inside container
we use this for local testing

Requrements:
- docker
- docker-compose

to run this test execute

docker-compose up --abort-on-container-exit && echo ok

In case of funny errors remove pubspec.lock in top dir
