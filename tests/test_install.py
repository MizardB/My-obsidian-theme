"""Offline sandbox checks of evaluated Nix installer scripts; never runs install apps.

Run: python3 -m unittest discover -s tests -v
Requires existing Nix inputs, Sass and jq in the store. No builds/downloads.
"""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def evaluated_script(app):
    expr = (
        'let f = builtins.getFlake (toString ./.); '
        f'p = f.apps.x86_64-linux.{app}.program; '
        'in builtins.head (builtins.attrNames (builtins.getContext p))'
    )
    drv = subprocess.check_output(
        ['nix', 'eval', '--offline', '--raw', '--impure', '--expr', expr],
        cwd=ROOT, text=True,
    ).strip()
    data = json.loads(subprocess.check_output(
        ['nix', 'derivation', 'show', '--offline', drv], cwd=ROOT, text=True,
    ))
    derivations = data.get('derivations', data)
    return next(iter(derivations.values()))['env']['text']


class InstallTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build = evaluated_script('build')
        cls.scripts = {app: evaluated_script(app) for app in ('install', 'install-dev')}
        for script in (cls.build, *cls.scripts.values()):
            subprocess.run(['bash', '-n'], input=script, text=True, check=True)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='mytheme-install-')
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.repo = self.base / 'repo'
        self.repo.mkdir()
        shutil.copytree(ROOT / 'src', self.repo / 'src')
        shutil.copyfile(ROOT / 'manifest.json', self.repo / 'manifest.json')
        (self.repo / 'theme.css').write_text('stale CSS')
        self.vault = self.base / 'vault'
        self.target = self.vault / '.obsidian/themes/Mytheme'
        self.target.mkdir(parents=True)
        self.appearance = self.vault / '.obsidian/appearance.json'
        self.appearance.write_text('{"cssTheme":"Other","accentColor":"red","nested":{"keep":true}}')
        self.build_file = self.base / 'build-theme'
        self.build_file.write_text(self.build)
        self.build_file.chmod(0o700)

    def run_install(self, app='install', success=True):
        # Only redirect the build wrapper to its evaluated text in our sandbox.
        script = re.sub(r'/nix/store/[^\s]+/bin/build-theme', str(self.build_file), self.scripts[app])
        result = subprocess.run(
            ['bash', '-c', script], cwd=self.repo,
            env={**os.environ, 'TARGET_VAULT': str(self.vault)},
            text=True, capture_output=True,
        )
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def test_stable_recompiles_and_copies_independently(self):
        self.run_install()
        for name in ('theme.css', 'manifest.json'):
            dest = self.target / name
            self.assertTrue(dest.is_file())
            self.assertFalse(dest.is_symlink())
            self.assertEqual(dest.read_bytes(), (self.repo / name).read_bytes())
            self.assertNotEqual(dest.stat().st_ino, (self.repo / name).stat().st_ino)
        css = (self.target / 'theme.css').read_bytes()
        self.assertNotEqual(css, b'stale CSS')
        (self.repo / 'theme.css').write_text('later edit')
        self.assertEqual((self.target / 'theme.css').read_bytes(), css)
        self.assertEqual(json.loads(self.appearance.read_text()), {
            'cssTheme': 'Mytheme', 'accentColor': 'red', 'nested': {'keep': True},
        })

    def test_migrate_individual_links_without_touching_their_sources(self):
        external = self.base / 'external'
        external.write_text('do not overwrite')
        (self.target / 'theme.css').symlink_to(external)
        (self.target / 'manifest.json').symlink_to(self.repo / 'manifest.json')
        manifest = (self.repo / 'manifest.json').read_bytes()
        self.run_install()
        self.assertEqual(external.read_text(), 'do not overwrite')
        self.assertEqual((self.repo / 'manifest.json').read_bytes(), manifest)
        self.assertFalse((self.target / 'theme.css').is_symlink())
        self.assertFalse((self.target / 'manifest.json').is_symlink())

    def test_dev_links_recompile_then_stable_disconnects(self):
        self.run_install()
        with (self.repo / 'src/theme.scss').open('a') as stream:
            stream.write('\n.sandbox-rebuild-proof { color: #123456; }\n')
        self.run_install('install-dev')
        for name in ('theme.css', 'manifest.json'):
            self.assertTrue((self.target / name).is_symlink())
            self.assertEqual((self.target / name).resolve(), self.repo / name)
        self.assertIn('.sandbox-rebuild-proof', (self.target / 'theme.css').read_text())
        (self.repo / 'theme.css').write_text('watch-style update')
        self.assertEqual((self.target / 'theme.css').read_text(), 'watch-style update')
        self.run_install()
        self.assertFalse((self.target / 'theme.css').is_symlink())
        self.assertIn('.sandbox-rebuild-proof', (self.target / 'theme.css').read_text())

    def test_compile_failure_does_not_install_or_select(self):
        (self.repo / 'src/theme.scss').write_text('.invalid { color: ;')
        before = self.appearance.read_bytes()
        self.run_install(success=False)
        self.run_install('install-dev', success=False)
        self.assertFalse((self.target / 'theme.css').exists())
        self.assertFalse((self.target / 'manifest.json').exists())
        self.assertEqual(self.appearance.read_bytes(), before)

    def test_absent_appearance_is_not_created(self):
        self.appearance.unlink()
        self.run_install()
        self.assertFalse(self.appearance.exists())

    def test_destination_directory_symlink_is_rejected_before_build(self):
        self.target.rmdir()
        self.target.symlink_to(self.repo, target_is_directory=True)
        before = self.appearance.read_bytes()
        self.run_install(success=False)
        self.run_install('install-dev', success=False)
        self.assertEqual((self.repo / 'theme.css').read_text(), 'stale CSS')
        self.assertEqual(self.appearance.read_bytes(), before)

    def test_source_equals_destination_is_rejected(self):
        # Point a parent at a directory whose Mytheme child is the repo.
        parent = self.base / 'alias-parent'
        parent.mkdir()
        moved = parent / 'Mytheme'
        self.repo.rename(moved)
        self.repo = moved
        self.target.rmdir()
        self.target.parent.rmdir()
        self.target.parent.symlink_to(parent, target_is_directory=True)
        self.run_install(success=False)
        self.run_install('install-dev', success=False)
        self.assertEqual((self.repo / 'theme.css').read_text(), 'stale CSS')

    def test_artifact_directory_is_preserved(self):
        (self.target / 'theme.css').mkdir()
        self.run_install(success=False)
        self.assertTrue((self.target / 'theme.css').is_dir())
        self.assertEqual((self.repo / 'theme.css').read_text(), 'stale CSS')


if __name__ == '__main__':
    unittest.main()
