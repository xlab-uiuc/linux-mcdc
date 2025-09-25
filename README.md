# Measure Linux kernel's modified condition/decision coverage (MC/DC)

[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/xlab-uiuc/linux-mcdc/llvm-trunk-linux-mainline.yml?label=LLVM%20trunk%2BLinux%20mainline)](https://github.com/xlab-uiuc/linux-mcdc/actions/workflows/llvm-trunk-linux-mainline.yml)

[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/xlab-uiuc/linux-mcdc/llvm-trunk-linux-v5.15.153.yml?label=LLVM%20trunk%2BLinux%20v5.15.153)](https://github.com/xlab-uiuc/linux-mcdc/actions/workflows/llvm-trunk-linux-v5.15.153.yml)

This repository demonstrates [KUnit](https://docs.kernel.org/dev-tools/kunit/index.html)'s
modified condition/decision coverage (MC/DC) of 5.15.y and mainline Linux kernel
using [Clang source-based code coverage](https://clang.llvm.org/docs/SourceBasedCodeCoverage.html)
and [`llvm-cov`](https://llvm.org/docs/CommandGuide/llvm-cov.html).

<!--
Primary
development of the kernel patch set is being performed in the [xlab-uiuc/llvm-cov](https://github.com/xlab-uiuc/linux-cov)
project.
-->

**Patches can be found under [`patches/`](patches/), or join LKML discussions:
[link](https://lore.kernel.org/lkml/20240824230641.385839-1-wentaoz5@illinois.edu/)**

Follow the instructions [here](docs/measure-kernel-mcdc.md) to get started.

Example text coverage report: [link](https://github.com/xlab-uiuc/linux-mcdc/actions/runs/10013137034/job/27681036852#step:8:7) (login with any GitHub account required)

Example HTML coverage report:

<img src="screenshot.png" width="70%">

We gave three talks in [LPC 2024](https://lpc.events/event/18/page/224-lpc-2024-overview):

- [Making Linux Fly: Towards a Certified Linux Kernel](https://lpc.events/event/18/contributions/1718/) (Refereed Track)
  [[recording](https://www.youtube.com/live/1KWkfHxTqYY?feature=shared&t=3957)]
  [[slides](https://lpc.events/event/18/contributions/1718/attachments/1584/3477/LPC'24%20Fly%20(no%20animation).pdf)]
- [Measuring and Understanding Linux Kernel Tests](https://lpc.events/event/18/contributions/1793/) (Kernel Testing & Dependability MC)
  [[recording](https://www.youtube.com/live/kcr8NXEbzcg?feature=shared&t=9380)]
  [[slides](https://lpc.events/event/18/contributions/1793/attachments/1624/3447/LPC'24%20Linux%20Testing.pdf)]
- [Source-based code coverage of Linux kernel](https://lpc.events/event/18/contributions/1895/) (Safe Systems with Linux MC)
  [[recording](https://www.youtube.com/live/kcr8NXEbzcg?feature=shared&t=23820)]
  [[slides](https://lpc.events/event/18/contributions/1895/attachments/1643/3462/LPC'24%20Source%20based%20(short).pdf)]

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
