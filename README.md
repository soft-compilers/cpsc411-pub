cpsc411-pub
=======
<p align="left">
  <a href="https://github.com/soft-compilers/cpsc411-pub/actions?query=workflow%3A%22CI%22"><img alt="GitHub Actions status" src="https://github.com/soft-compilers/cpsc411-pub/workflows/CI/badge.svg"></a>
</p>

This collection defines the public support code for the VUB's course "Compilers".
The course are based on a similar course at the University of British Columbia
and this repo is derived from UBC's [original support code](https://github.com/cpsc411/cpsc411-pub.git).

This code is meant distributed to students as they work through the assignments
described by the `cpsc411-book` package.

## Installation
From the `cpsc411-lib` directory, run `raco pkg install`, or run
`raco pkg install https://github.com/soft-compilers/cpsc411-pub.git?path=cpsc411-lib`.

If you get strange errors referencing `cpsc411-pub`, you may have run the
command from the wrong directory.
Try doing `raco pkg remove cpsc411-pub` and running the command from the
directory as described above.
