"""Freshness of cq_pass-sync's generated KeePass export; checks never decrypt."""
import os, stat
from pathlib import Path
from ..model import now
from ..util import Problem, require
from .base import action

WEEK = 7 * 86400


def paths(ctx):
    store = Path(ctx.options.get('store') or os.environ.get('PASSWORD_STORE_DIR') or '~/Sync/Password-Store').expanduser().resolve()
    def inside(name, default):
        path = Path(ctx.options.get(name, default)).expanduser()
        return path if path.is_absolute() else store / path
    return store, inside('kdbx', 'passwords.kdbx'), inside('base_kdbx', 'empty.kdbx')


def check(ctx):
    _, database, _ = paths(ctx)
    warning = int(ctx.options.get('warning_seconds', WEEK))
    error = int(ctx.options.get('error_seconds', 2 * WEEK))
    if not 0 < warning < error:
        raise Problem('pass-sync requires 0 < warning_seconds < error_seconds')
    actions = [action('Export password store to KeePass')]
    details = [
        'Export database: ' + str(database),
        'Freshness uses the generated database modification time, including exports received via Syncthing.',
        f'Warn after {warning / 86400:g} days; error after {error / 86400:g} days.',
        'Run cq_maintenance fix ' + ctx.id + ' to export now; the foreground command may ask for the KeePass password.',
    ]
    metrics = {'kdbx': str(database), 'timestamp_source': 'export_mtime'}
    try:
        info = database.stat()
    except FileNotFoundError:
        return ctx.result('error', 'No KeePass export found', details=details, metrics=metrics, actions=actions)
    if not stat.S_ISREG(info.st_mode) or not info.st_size:
        return ctx.result('error', 'KeePass export is empty or not a regular file', details=details, metrics=metrics, actions=actions)
    stamp = info.st_mtime
    if stamp <= 0 or stamp > now() + 60:
        details.append('Export timestamp is invalid or in the future; check the machine clock and Syncthing timestamps.')
        return ctx.result('warning', 'Cannot determine KeePass export age', details=details, metrics=metrics, actions=actions)
    age = max(0, now() - stamp)
    state = 'error' if age > error else 'warning' if age > warning else 'ok'
    metrics['age_seconds'] = age
    return ctx.result(state, f'Last KeePass export {int(age // 86400)}d {int(age % 86400 // 3600)}h ago',
                      details=details, metrics=metrics, last_success=stamp, actions=actions)


def execute(ctx, id):
    if id != 'fix':
        raise Problem('Unsupported password-sync action')
    store, database, base = paths(ctx)
    if not store.is_dir():
        raise Problem('Password store is missing; restore it or configure options.store first')
    if not base.is_file():
        raise Problem('KeePass base database is missing; restore it or configure options.base_kdbx first')
    from .crypt import environment
    env = environment(ctx)
    env['PASSWORD_STORE_DIR'] = str(store)
    require(ctx.run(['cq_pass-sync', 'export', '--store', str(store), '--base-kdbx', str(base), '--kdbx', str(database)],
                    env=env, cwd=store, foreground=True, timeout=3600))
    return 'KeePass export completed'


def open(ctx):
    return ['cq_maintenance', 'tui', '--select', ctx.id]
