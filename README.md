# eks-automode

The Simplified Stack: EKS [Auto Mode]

This is intended to be a test environment for learning new technologies quickly.

There are some [noteable changes] with this version.

## Quick Start

Pull in the build variables into the environment.

```shell
source build.env stage

make init
make plan
make apply
make destroy
```

Everythign just happens in about 20 minutes.

<!-- docs/refs -->

[Auto Mode]:https://docs.aws.amazon.com/eks/latest/userguide/automode.html
[noteable changes]:https://github.com/todd-dsm/eks-automode/tree/main/docs
