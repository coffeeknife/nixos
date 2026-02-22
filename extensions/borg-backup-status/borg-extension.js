import GLib from 'gi://GLib';
import Clutter from 'gi://Clutter';
import St from 'gi://St';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

export default class BorgBackupStatusExtension extends Extension {
  enable() {
    this._indicator = new PanelMenu.Button(0.0, this.metadata.name, false);
    let box = new St.BoxLayout({style_class: 'panel-status-menu-box'});
    this._icon = new St.Icon({
      icon_name: 'drive-harddisk-symbolic',
      style_class: 'system-status-icon',
    });
    this._label = new St.Label({
      text: '',
      y_align: Clutter.ActorAlign.CENTER,
    });
    box.add_child(this._icon);
    box.add_child(this._label);
    this._indicator.add_child(box);

    // Menu items
    this._statusItem = new PopupMenu.PopupMenuItem('No backup yet', {reactive: false});
    this._indicator.menu.addMenuItem(this._statusItem);
    this._indicator.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

    let backupNow = new PopupMenu.PopupMenuItem('Back Up Now');
    backupNow.connect('activate', () => {
      GLib.spawn_command_line_async('systemctl --user start borgbackup-home');
      this._updateSoon();
    });
    this._indicator.menu.addMenuItem(backupNow);

    this._indicator.menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());

    let browseAll = new PopupMenu.PopupMenuItem('Browse All Backups');
    browseAll.connect('activate', () => {
      GLib.spawn_command_line_async('borg-browse');
    });
    this._indicator.menu.addMenuItem(browseAll);

    let browseLatest = new PopupMenu.PopupMenuItem('Browse Latest Backup');
    browseLatest.connect('activate', () => {
      GLib.spawn_command_line_async('borg-browse --latest');
    });
    this._indicator.menu.addMenuItem(browseLatest);

    let unmount = new PopupMenu.PopupMenuItem('Unmount Backups');
    unmount.connect('activate', () => {
      GLib.spawn_command_line_async('borg-umount');
    });
    this._indicator.menu.addMenuItem(unmount);

    Main.panel.addToStatusArea(this.uuid, this._indicator, -1, 'left');
    this._update();
    this._timerId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 300, () => {
      this._update();
      return GLib.SOURCE_CONTINUE;
    });
  }

  _updateSoon() {
    GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 3, () => {
      this._update();
      return GLib.SOURCE_REMOVE;
    });
  }

  _update() {
    try {
      let [ok, stdout] = GLib.spawn_command_line_sync(
        'systemctl --user show borgbackup-home.service --property=ActiveState,ExecMainStatus,ExecMainExitTimestamp'
      );
      if (!ok) return;
      let props = {};
      for (let line of new TextDecoder().decode(stdout).split('\n')) {
        let i = line.indexOf('=');
        if (i > 0) props[line.substring(0, i)] = line.substring(i + 1);
      }
      let active = props['ActiveState'];
      let exit = props['ExecMainStatus'];
      let ts = props['ExecMainExitTimestamp'];
      if (active === 'active' || active === 'activating') {
        this._icon.icon_name = 'emblem-synchronizing-symbolic';
        this._label.text = ' Backing up\u2026';
        this._statusItem.label.text = 'Backup in progress\u2026';
        this._updateSoon();
      } else if (exit === '0' && ts) {
        this._icon.icon_name = 'emblem-ok-symbolic';
        this._label.text = ' ' + this._relative(ts);
        this._statusItem.label.text = 'Last backup: ' + this._relative(ts);
      } else if (exit && exit !== '0') {
        this._icon.icon_name = 'dialog-warning-symbolic';
        this._label.text = ' Backup failed';
        this._statusItem.label.text = 'Last backup failed';
      } else {
        this._icon.icon_name = 'drive-harddisk-symbolic';
        this._label.text = '';
        this._statusItem.label.text = 'No backup yet';
      }
    } catch (e) { logError(e, 'BorgBackupStatus'); }
  }

  _relative(ts) {
    try {
      let p = ts.trim().split(/\s+/);
      if (p.length < 3) return '';
      let [y, m, d] = p[1].split('-').map(Number);
      let [H, M, S] = p[2].split(':').map(Number);
      let then = GLib.DateTime.new_local(y, m, d, H, M, S);
      let now = GLib.DateTime.new_now_local();
      let s = now.difference(then) / 1000000;
      if (s < 60) return 'just now';
      if (s < 3600) return Math.floor(s / 60) + 'm ago';
      if (s < 86400) return Math.floor(s / 3600) + 'h ago';
      return Math.floor(s / 86400) + 'd ago';
    } catch (e) { return ''; }
  }

  disable() {
    if (this._timerId) { GLib.source_remove(this._timerId); this._timerId = null; }
    this._indicator?.destroy();
    this._indicator = null;
  }
}
