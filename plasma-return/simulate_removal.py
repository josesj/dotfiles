#!/usr/bin/env python3
"""Simula, sobre una COPIA de la base de datos local de pacman, qué se eliminaría al
dejar sólo los paquetes «base» como explícitos y quitar los huérfanos.

No toca el sistema: trabaja en un directorio temporal y no necesita root.
Uso: simulate_removal.py BASE.txt GUI.txt [--out QUITAR.txt] [--protect FICHERO]
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

LOCAL = '/var/lib/pacman/local'


def names(path):
    return {l.strip() for l in open(path) if l.strip() and not l.startswith('#')}


def set_reason(desc_path, explicit):
    text = open(desc_path).read()
    text = re.sub(r'%REASON%\n\d+\n\n?', '', text)
    if not explicit:
        text = text.rstrip('\n') + '\n\n%REASON%\n1\n\n'
    open(desc_path, 'w').write(text)


def orphans(dbpath):
    out = subprocess.run(['pacman', '--dbpath', dbpath, '-Qdttq'], capture_output=True, text=True)
    return [l for l in out.stdout.split() if l]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('base')
    ap.add_argument('gui')
    ap.add_argument('--out')
    ap.add_argument('--protect', help='paquetes que NUNCA deben salir (uno por línea)')
    a = ap.parse_args()
    base, gui = names(a.base), names(a.gui)
    protect = names(a.protect) if a.protect else set()

    tmp = tempfile.mkdtemp(prefix='plasma-return-db-')
    try:
        db = os.path.join(tmp, 'db')
        os.makedirs(db)
        shutil.copytree(LOCAL, os.path.join(db, 'local'))
        # nombre de paquete -> carpeta
        folder = {}
        for d in os.listdir(os.path.join(db, 'local')):
            m = re.match(r'(.+)-[^-]+-[^-]+$', d)
            if m:
                folder[m.group(1)] = d
        for n in gui:
            if n in folder:
                set_reason(os.path.join(db, 'local', folder[n], 'desc'), explicit=False)
        for n in base:
            if n in folder:
                set_reason(os.path.join(db, 'local', folder[n], 'desc'), explicit=True)

        removed = []
        for _ in range(60):
            orph = orphans(db)
            if not orph:
                break
            removed += orph
            for n in orph:
                if n in folder:
                    shutil.rmtree(os.path.join(db, 'local', folder[n]), ignore_errors=True)
        total = len(folder)
        print(f'paquetes instalados ahora : {total}', file=sys.stderr)
        print(f'se quitarían              : {len(removed)}', file=sys.stderr)
        print(f'quedarían                 : {total - len(removed)}', file=sys.stderr)
        hit = sorted(protect & set(removed))
        if hit:
            print('¡ATENCIÓN! saldrían paquetes protegidos: ' + ', '.join(hit), file=sys.stderr)
            sys.exit(3)
        if a.out:
            open(a.out, 'w').write('\n'.join(sorted(removed)) + '\n')
        else:
            print('\n'.join(sorted(removed)))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    main()
