# Measure Linux kernel's modified condition/decision coverage (MC/DC)

[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/xlab-uiuc/linux-mcdc/llvm-19.yml?label=LLVM%2019)](https://github.com/xlab-uiuc/linux-mcdc/actions/workflows/llvm-19.yml)
[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/xlab-uiuc/linux-mcdc/llvm-18.yml?label=LLVM%2018)](https://github.com/xlab-uiuc/linux-mcdc/actions/workflows/llvm-18.yml)

Example text coverage report: [link](https://github.com/xlab-uiuc/linux-mcdc/actions/runs/9639450937/job/26582312842#step:5:7)

Example HTML coverage report:

<img src="screenshot.png" width="70%">

[[Get started (LLVM 19)](https://github.com/xlab-uiuc/linux-mcdc/blob/llvm19/docs/measure-kernel-mcdc.md)]
            [[(LLVM 18)](https://github.com/xlab-uiuc/linux-mcdc/blob/public-approved/docs/measure-kernel-mcdc.md)]

More materials will be posted here as soon as they are approved. Please stay
tuned!

Tentative repository structure:

```text
linux-mcdc
│
├── docs
│   ├── elisa-slides.pdf
│   └── measure-kernel-mcdc.md
│
├── scripts
│   ├── build-llvm.sh
│   └── q
│
├── patches
│   ├── README.md
│   └── {v0.4,v0.5,v0.6}
│
├── screenshot.png
└── README.md
```

We gave an ELISA seminar titled "Making Linux Fly: Towards Certified Linux
Kernel".
[[recording](https://elisa.tech/blog/2024/05/28/making-linux-fly-towards-certified-linux-kernel/)]
[[slides](./docs/elisa-slides.pdf)]

Please feel free to open Issues/PRs if you have any suggestions or questions.
You can also send emails to:

- Steven H. VanderLeest \<Steven.H.VanderLeest@boeing.com\>
- Wentao Zhang \<wentaoz5@illinois.edu\>

This project is a collaboration between The Boeing Company and University of
Illinois Urbana-Champaign.
