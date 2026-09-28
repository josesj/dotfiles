# Usage in a project's .envrc:
#   use uv          # Python selected by pyproject.toml/.python-version
#   use uv 3.13     # Explicit Python version
use_uv() {
  local python_version="${1:-}"

  if ! has uv; then
    log_error 'uv no está instalado o no aparece en PATH'
    return 1
  fi
  if [[ ! -f pyproject.toml ]]; then
    log_error 'use uv requiere un pyproject.toml en el directorio actual'
    return 1
  fi

  watch_file pyproject.toml
  [[ ! -f uv.lock ]] || watch_file uv.lock

  if [[ -n "$python_version" ]]; then
    uv sync --python "$python_version" || return
  else
    uv sync || return
  fi

  export VIRTUAL_ENV="$PWD/.venv"
  PATH_add "$VIRTUAL_ENV/bin"
}

