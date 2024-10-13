# Lab Deployment

This repository contains the components needed for the instructor to deploy the lab environment. It is not meant to be used by students.

## How to deploy?

1. Provide the number of attendees by updating `attendees` field in [values.yaml](charts/values.yaml).

2. Run `install.sh` script to install:
    - IPA for user management
    - Operators such as OpenShift AI, User Workload Monitoring
    - Components such as Data Science Project, DSPA, Minio, Model Registry and so on

    ```bash

    ./install.sh

    ```
