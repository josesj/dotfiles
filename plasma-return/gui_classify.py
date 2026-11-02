#!/usr/bin/env python3
"""Clasifica los paquetes instalados explícitamente en «gráficos» y «base».

Un paquete es gráfico si cumple alguna de estas reglas (se imprime la causa):
  group   pertenece a un grupo de escritorio (plasma, kde-*, gnome, gnome-extra...)
  app     instala un lanzador .desktop visible y que no abre una terminal
  toolkit depende, directa o indirectamente, de un toolkit gráfico (GTK, Qt, SDL...)
  force   figura en el fichero de excepciones «gráficos»
Un paquete que cumple alguna regla pero está en el fichero de excepciones «base»
se queda como base.

Uso: gui_classify.py [--base-keep FICHERO] [--gui-force FICHERO] [--show base|gui|why]
"""
import argparse
import re
import subprocess
import sys

TOOLKITS = {
    'gtk2', 'gtk3', 'gtk4', 'libadwaita', 'adw-gtk-theme', 'qt5-base', 'qt6-base',
    'wxwidgets-gtk3', 'wxwidgets-common', 'electron', 'xorg-server', 'xorg-xwayland',
}
DESKTOP_GROUPS = re.compile(r'^(plasma|kde-.*|kf5.*|kf6.*|kdemultimedia.*|gnome|gnome-extra|'
                            r'gnome-circle|xfce.*|lxqt|mate.*|cinnamon|budgie.*)$')


def run(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout


def read_list(path):
    if not path:
        return set()
    try:
        return {l.split('#')[0].strip() for l in open(path) if l.split('#')[0].strip()}
    except FileNotFoundError:
        return set()


def parse_installed():
    """pkg -> (deps, provides, groups) desde `pacman -Qi`."""
    pkgs, current = {}, None
    for line in run('pacman', '-Qi').splitlines():
        if line.startswith('Name'):
            current = line.split(':', 1)[1].strip()
            pkgs[current] = {'deps': [], 'prov': [], 'groups': [], 'reason': ''}
        elif current and line.startswith('Depends On'):
            v = line.split(':', 1)[1].strip()
            pkgs[current]['deps'] = [] if v == 'None' else [re.split(r'[<>=]', t)[0] for t in v.split()]
        elif current and line.startswith('Provides'):
            v = line.split(':', 1)[1].strip()
            pkgs[current]['prov'] = [] if v == 'None' else [re.split(r'[<>=]', t)[0] for t in v.split()]
        elif current and line.startswith('Groups'):
            v = line.split(':', 1)[1].strip()
            pkgs[current]['groups'] = [] if v == 'None' else v.split()
        elif current and line.startswith('Install Reason'):
            pkgs[current]['reason'] = 'explicit' if 'Explicit' in line else 'dep'
    return pkgs


def desktop_apps():
    """paquetes que instalan algún .desktop visible y que no abre terminal."""
    out = run('pacman', '-Ql')
    pkg_of = {}
    for line in out.splitlines():
        p, _, path = line.partition(' ')
        if path.startswith('/usr/share/applications/') and path.endswith('.desktop'):
            pkg_of[path] = p
    gui = set()
    for path, p in pkg_of.items():
        try:
            text = open(path, errors='ignore').read()
        except OSError:
            continue
        if re.search(r'^NoDisplay\s*=\s*true', text, re.M | re.I):
            continue
        if re.search(r'^Terminal\s*=\s*true', text, re.M | re.I):
            continue
        if not re.search(r'^Exec\s*=', text, re.M):
            continue
        gui.add(p)
    return gui


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base-keep')
    ap.add_argument('--gui-force')
    ap.add_argument('--show', default='why', choices=['base', 'gui', 'why'])
    a = ap.parse_args()
    base_keep, gui_force = read_list(a.base_keep), read_list(a.gui_force)

    pkgs = parse_installed()
    provider = {}
    for name, d in pkgs.items():
        provider[name] = name
        for pr in d['prov']:
            provider.setdefault(pr, name)

    apps = desktop_apps()
    # Paquetes que son gráficos por sí mismos (cualquiera instalado, explícito o no).
    own = {}
    for n, d in pkgs.items():
        if n in base_keep:
            continue
        if n in gui_force:
            own[n] = 'force'
        elif any(DESKTOP_GROUPS.match(g) for g in d['groups']):
            own[n] = 'group:' + ','.join(g for g in d['groups'] if DESKTOP_GROUPS.match(g))
        elif n in TOOLKITS:
            own[n] = 'toolkit'
        elif n in apps:
            own[n] = 'app'

    memo = {}
    def via(name, stack=()):
        """causa por la que `name` es gráfico (él mismo o por sus dependencias)."""
        if name in memo:
            return memo[name]
        if name in own:
            memo[name] = own[name]
            return memo[name]
        if name in base_keep or name in stack or name not in pkgs:
            return None
        result = None
        for dep in pkgs[name]['deps']:
            real = provider.get(dep, dep)
            if real == name:
                continue
            hit = via(real, stack + (name,))
            if hit:
                result = f'dep:{real}({hit.split(":")[0].split("(")[0]})'
                break
        memo[name] = result
        return result

    explicit = sorted(n for n, d in pkgs.items() if d['reason'] == 'explicit')
    gui, base = {}, []
    for n in explicit:
        why = via(n)
        if why:
            gui[n] = why
        else:
            base.append(n)

    if a.show == 'base':
        print('\n'.join(base))
    elif a.show == 'gui':
        print('\n'.join(gui))
    else:
        print(f'# explícitos: {len(explicit)}  base: {len(base)}  gráficos: {len(gui)}', file=sys.stderr)
        for n, why in sorted(gui.items()):
            print(f'{n:34} {why}')


if __name__ == '__main__':
    main()
