# just-kit by Fabian

## Usage

### Preconditions

#### [just-kit](https://github.com/bibermann/just-kit)

Clone <https://github.com/bibermann/just-kit> to `<just-kit directory>`
(replace by proper location, e.g. `~/.just/kit`).

#### Naming

- With _this project_ I refer to the project containing this README.
- With _example project_ I refer to your project where you want to enable the tools.

### Setup

Clone _this project_ to a proper location, e.g.: `~/.just/bibermann`

#### Enhance an _example project_

1. If the project roots of _just-kit_ or _this project_ are not within a `.just` directory
   in one of the _example project_'s parent directories, add the following line
   to the `.env` file in the _example project_ root
   (replace with proper paths or skip paths already in proper parent directories):

   ```bash
   EXTRA_JUST_ROOTS="<just-kit directory>:<this project directory>"
   ```

2. In an _example project_'s root, run `<just-kit directory>/setup.sh`
   (replace `<just-kit directory>` with the _just-kit_ repository location).
3. Select and confirm all `*.just` files you want to use from within the _example project_.

Hints:

- To update the selection, run `just pick`.
- To enhance your bash session, run `source just-bash` (this is not permanent).

## Development

### Preconditions

#### just-kit

Read and understand the _just-kit_ README.

### How to extend

Instead of contributing to this project, you may create your own recipes,
eventually replacing a `*.just` file in this project with your version
by simply switching through `just pick`.

### Setup for development

1. If the project root of _just-kit_ is not within a `.just` directory
   in one of _this project_'s parent directories, add the following line
   to the `.env` file in _this project_'s root
   (replace `<just-kit directory>` with the _just-kit_ repository location):

   ```bash
   EXTRA_JUST_ROOTS="<just-kit directory>"
   ```

2. In _this project_'s root, run `<just-kit directory>/setup.sh`
   (replace `<just-kit directory>` with the _just-kit_ repository location).
3. Select and confirm those options:
   - `core`
   - `pre-commit-with-uv`
   - `uv`
4. When asked to choose the overriding path,
   select `pre-commit-with-uv.just` and `uv.just` respectively over `core.just`
   (press `2` and `[Enter]` two times).
5. Run `just _install-pre-commit` (or `just pre-commit` which will also run pre-commit).
