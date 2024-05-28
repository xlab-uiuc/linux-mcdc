This project is a collaboration between The Boeing Company and University of
Illinois Urbana-Champaign.

[Get started](./docs/measure-kernel-mcdc.md)

More materials will be posted here as soon as they are approved. Please stay
tuned!

Tentative repository structure:

```text
linux-mcdc
│
├── docs
│   └── measure-kernel-mcdc.md
│
├── scripts
│   ├── build-llvm.sh
│   └── q
│
├── patches
│   ├── README.md
│   └── v0.4
│       ├── 0000-cover-letter.patch
│       ├── 0001-clang_instr_profile-add-Clang-s-Source-based-Code-Co.patch
│       ├── 0002-kbuild-clang_instr_profile-disable-instrumentation-i.patch
│       └── 0003-clang_instr_profile-add-Clang-s-MC-DC-support.patch
│
└── README.md
```

We gave an ELISA seminar titled "Making Linux Fly: Towards Certified Linux
Kernel". More information can be found here:
https://elisa.tech/event/elisa-seminar-making-linux-fly-towards-certified-linux-kernel/.
Slides and recording will be uploaded by ELISA organizers as well.

Please feel free to open Issues/PRs if you have any suggestions or questions.
You can also send emails to:

- Steven H. VanderLeest <Steven.H.VanderLeest@boeing.com>
- Wentao Zhang <wentaoz5@illinois.edu>