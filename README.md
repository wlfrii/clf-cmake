> CLF —— <b>C</b>++ & <b>C</b>omputer Vision & <b>C</b>omputer Graphics & Kinematics <b>C</b>onfiguration <b>L</b>earning <b>F</b>ramework
> 
# clf::cmake

Common CMake function definitions for the personal CLF projects.

## Introduction

`clf.cmake` defines common functions.

`template-CMakeLists.txt` presents a template `CMakeLists` file that configured with common functions. 

`template-config.cmake.in` is a package configuration template used to make an
installed project available through `find_package()`.

## Usage

Add this project to new project as a submodule:

```sh
git submodule add <repository-url> clf-cmake
```

Copy `template-CMakeLists.txt` to the project as `CMakeLists.txt`, replace its
placeholder project and dependency names, then copy `template-config.cmake.in`
to `cmake/<project-name>-config.cmake.in`.

`find_required_library(package component1 component2)` treats arguments after
the package name as components. Prefer imported targets provided by packages
when calling `target_link_libraries()`.

For CUDA projects, enable CUDA in `project(LANGUAGES CXX CUDA)` and select GPU
architectures with `CMAKE_CUDA_ARCHITECTURES` (or the target property
`CUDA_ARCHITECTURES`) before calling `clf_cuda_common_set()`.
