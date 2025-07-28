# eks-automode

The Simplified Stack: EKS [Auto Mode]

This is intended to be a test environment for learning new technologies quickly; this is NOT for any sort of production use.

There are some [noteable changes] with this version.

## Quick Start

Edit `build.env` and pull those build variables into the environment.

```shell
source build.env stage  # Generate environment config
make infras             # Stage 1: Deploy infrastructure (networking + eks-core)
make addons             # Stage 2: Deploy all addons (requires running cluster)
```

The build happens in `~16` minutes.

<!-- docs/refs -->

[Auto Mode]:https://docs.aws.amazon.com/eks/latest/userguide/automode.html
[noteable changes]:https://github.com/todd-dsm/eks-automode/tree/main/docs
