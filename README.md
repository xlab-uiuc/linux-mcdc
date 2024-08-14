# Measure Linux kernel's modified condition/decision coverage (MC/DC)

[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/xlab-uiuc/linux-mcdc/llvm-trunk.yml?label=LLVM%20trunk)](https://github.com/xlab-uiuc/linux-mcdc/actions/workflows/llvm-trunk.yml)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/xlab-uiuc/linux-mcdc/llvm-18.yml?label=LLVM%2018)](https://github.com/xlab-uiuc/linux-mcdc/actions/workflows/llvm-18.yml)

This repository demonstrates [KUnit](https://docs.kernel.org/dev-tools/kunit/index.html)'s
modified condition/decision coverage (MC/DC) of 5.15.y Linux kernel using
[Clang source-based code coverage](https://clang.llvm.org/docs/SourceBasedCodeCoverage.html)
and [`llvm-cov`](https://llvm.org/docs/CommandGuide/llvm-cov.html). A patch set
for mainline kernel is also being prepared.

<!--
Primary
development of the kernel patch set is being performed in the [xlab-uiuc/llvm-cov](https://github.com/xlab-uiuc/linux-cov)
project.
-->

Follow the instructions [here](docs/measure-kernel-mcdc.md) to get started.

Example text coverage report: [link](https://github.com/xlab-uiuc/linux-mcdc/actions/runs/10013137034/job/27681036852#step:8:7) (login with any GitHub account required)

Example HTML coverage report:

<img src="screenshot.png" width="70%">

Tentative repository structure:

```text
linux-mcdc
|
├── ci/{linux-v5.15.153}
│   ├── 1_install_deps.sh
│   ├── 2_pull_source.sh
│   ├── 3_get_llvm.sh
│   ├── 4_build_kernel.sh
│   └── 5_boot_kernel_and_collect_coverage.sh
|
├── docs
│   ├── elisa-slides.pdf
│   └── measure-kernel-mcdc.md
|
├── patches
│   ├── README.md
│   └── {v0.4,v0.5,v0.6}
|
├── README.md
|
├── screenshot.png
|
└── scripts
    ├── build-llvm.sh
    └── q
```

We gave an [ELISA](https://elisa.tech/) seminar titled "Making Linux Fly: Towards Certified Linux
Kernel".
[[recording](https://elisa.tech/blog/2024/05/28/making-linux-fly-towards-certified-linux-kernel/)]
[[slides](./docs/elisa-slides.pdf)]

Please feel free to open Issues/PRs if you have any suggestions or questions.
You can also send emails to:

- Steven H. VanderLeest \<Steven.H.VanderLeest@boeing.com\>
- Wentao Zhang \<wentaoz5@illinois.edu\>

This project is a collaboration between The Boeing Company and University of
Illinois Urbana-Champaign.
