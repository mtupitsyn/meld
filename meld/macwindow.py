# Copyright (C) 2002-2006 Stephen Kennedy <stevek@gnome.org>
# Copyright (C) 2010-2013 Kai Willadsen <kai.willadsen@gmail.com>
# Copyright (C) 2019-2019 Youssef Abukwaik <youssef.adnan@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import ctypes
from Cocoa import NSApp
from Cocoa import NSApplicationActivateIgnoringOtherApps, NSApplicationActivateAllWindows
from AppKit import NSBundle, NSApp, NSWindow, NSAutoreleasePool, NSApplicationActivationPolicyRegular, NSApplicationActivationPolicyProhibited

from gi.repository import Gdk
from gi.repository import Gio
from gi.repository import GLib
from gi.repository import Gtk

import gi
gi.require_version('GtkosxApplication', '1.0') 
from gi.repository import GtkosxApplication as gtkosx_application

from meld.conf import _, ui_file
from meld.recent import recent_comparisons, RecentType

class MacWindow:
    is_quartz = True

    def install_mac_additions(self):

        #header_bar = Gtk.Template.Child()
        self.maximize_button = Gtk.Template.Child()

        # Manually handle GAction additions
        actions = (
            ("close-window", self.action_close_window),
            ("minimize-window", self.action_minimize_window),
            ("maximize-window", self.action_maximize_window),
        )
        for name, callback in actions:
            action = Gio.SimpleAction.new(name, None)
            action.connect('activate', callback)
            self.add_action(action)

        # Menu actions
        actions = (
            ("FileMenu", None, _("_File")),
            ("New", Gtk.STOCK_NEW, _("_New Comparison…"), "<Primary>N",
                _("Start a new comparison"),
                self.on_menu_file_new_activate),
            ("Save", Gtk.STOCK_SAVE, None, None,
                _("Save the current file"),
                self.on_menu_save_activate),
            ("SaveAs", Gtk.STOCK_SAVE_AS, _("Save As…"), "<Primary><shift>S",
                _("Save the current file with a different name"),
                self.on_menu_save_as_activate),
            ("Close", Gtk.STOCK_CLOSE, None, None,
                _("Close the current file"),
                self.on_menu_close_activate),

            ("EditMenu", None, _("_Edit")),
            ("Undo", Gtk.STOCK_UNDO, None, "<Primary>Z",
                _("Undo the last action"),
                self.on_menu_undo_activate),
            ("Redo", Gtk.STOCK_REDO, None, "<Primary><shift>Z",
                _("Redo the last undone action"),
                self.on_menu_redo_activate),
            ("Cut", Gtk.STOCK_CUT, None, None, _("Cut the selection"),
                self.on_menu_cut_activate),
            ("Copy", Gtk.STOCK_COPY, None, None, _("Copy the selection"),
                self.on_menu_copy_activate),
            ("Paste", Gtk.STOCK_PASTE, None, None, _("Paste the clipboard"),
                self.on_menu_paste_activate),
            ("Find", Gtk.STOCK_FIND, _("Find…"), None, _("Search for text"),
                self.on_menu_find_activate),
            ("FindNext", None, _("Find Ne_xt"), "<Primary>G",
                _("Search forwards for the same text"),
                self.on_menu_find_next_activate),
            ("FindPrevious", None, _("Find _Previous"), "<Primary><shift>G",
                _("Search backwards for the same text"),
                self.on_menu_find_previous_activate),
            ("Replace", Gtk.STOCK_FIND_AND_REPLACE,
                _("_Replace…"), "<Primary>H",
                _("Find and replace text"),
                self.on_menu_replace_activate),
            ("GoToLine", None, _("Go to _Line"), "<Primary>I",
                _("Go to a specific line"),
                self.on_menu_go_to_line_activate),

            ("ChangesMenu", None, _("_Changes")),
            ("NextChange", Gtk.STOCK_GO_DOWN, _("Next Change"), "<Alt>Down",
                _("Go to the next change"),
                self.on_menu_edit_down_activate),
            ("PrevChange", Gtk.STOCK_GO_UP, _("Previous Change"), "<Alt>Up",
                _("Go to the previous change"),
                self.on_menu_edit_up_activate),
            ("OpenExternal", None, _("Open Externally"), None,
                _("Open selected file or directory in the default external "
                    "application"),
                self.on_open_external),

            ("ViewMenu", None, _("_View")),
            ("FileStatus", None, _("File Status")),
            ("VcStatus", None, _("Version Status")),
            ("FileFilters", None, _("File Filters")),
            ("Stop", Gtk.STOCK_STOP, None, "Escape",
                _("Stop the current action"),
                self.on_toolbar_stop_clicked),
            ("Refresh", Gtk.STOCK_REFRESH, None, "<Primary>R",
                _("Refresh the view"),
                self.on_menu_refresh_activate),
        )

        self.actiongroup = Gtk.ActionGroup(name='MainActions')
        self.actiongroup.set_translation_domain("meld")
        self.actiongroup.add_actions(actions)

        recent_action = Gtk.RecentAction(
            name="Recent",  label=_("Open Recent"),
            tooltip=_("Open recent files"), stock_id=None)
        recent_action.set_show_private(True)
        recent_action.set_filter(recent_comparisons.recent_filter)
        recent_action.set_sort_type(Gtk.RecentSortType.MRU)
        recent_action.connect("item-activated", self.on_action_recent)
        self.actiongroup.add_action(recent_action)

        self.ui = Gtk.UIManager()
        self.ui.insert_action_group(self.actiongroup, 0)
        self.ui.add_ui_from_file(ui_file("meldapp-ui.xml"))

        for menuitem in ("Save", "Undo"):
            self.actiongroup.get_action(menuitem).props.is_important = True
        self.add_accel_group(self.ui.get_accel_group())
        self.menubar = self.ui.get_widget('/Menubar')

        self.menubar.hide()
        self.quartz_ready = False

        # Alternate keybindings for a few commands.
        extra_accels = (
            ("<Primary>D", self.on_menu_edit_down_activate),
            ("<Primary>E", self.on_menu_edit_up_activate),
            ("<Alt>KP_Down", self.on_menu_edit_down_activate),
            ("<Alt>KP_Up", self.on_menu_edit_up_activate),
            ("F5", self.on_menu_refresh_activate),
        )

        accel_group = self.ui.get_accel_group()
        for accel, callback in extra_accels:
            keyval, mask = Gtk.accelerator_parse(accel)
            accel_group.connect(keyval, mask, 0, callback)

        self.connect('window-state-event', self.on_window_state_event)

    def on_window_state_event(self, window, event):
        # FIXME: We don't receive notification on fullscreen on OSX
        # We'll have to figure this out some other way..
        pass

    def on_menu_file_new_activate(self, menuitem):
        self.append_new_comparison()

    def on_menu_save_activate(self, menuitem):
        self.current_doc().save()

    def on_menu_save_as_activate(self, menuitem):
        self.current_doc().save_as()

    def on_action_recent(self, action):
        uri = action.get_current_uri()
        if not uri:
            return
        try:
            self.append_recent(uri)
        except (IOError, ValueError):
            # FIXME: Need error handling, but no sensible display location
            pass

    def on_menu_close_activate(self, *extra):
        i = self.notebook.get_current_page()
        if i >= 0:
            page = self.notebook.get_nth_page(i)
            page.on_delete_event()

    def on_menu_undo_activate(self, *extra):
        self.current_doc().on_undo_activate()

    def on_menu_redo_activate(self, *extra):
        self.current_doc().on_redo_activate()

    def on_menu_refresh_activate(self, *extra):
        self.current_doc().on_refresh_activate()

    def on_menu_find_activate(self, *extra):
        self.current_doc().on_find_activate()

    def on_menu_find_next_activate(self, *extra):
        self.current_doc().on_find_next_activate()

    def on_menu_find_previous_activate(self, *extra):
        self.current_doc().on_find_previous_activate()

    def on_menu_replace_activate(self, *extra):
        self.current_doc().on_replace_activate()

    def on_menu_go_to_line_activate(self, *extra):
        self.current_doc().on_go_to_line_activate()

    def on_menu_copy_activate(self, *extra):
        widget = self.get_focus()
        if isinstance(widget, Gtk.Editable):
            widget.copy_clipboard()
        elif isinstance(widget, Gtk.TextView):
            widget.emit("copy-clipboard")

    def on_menu_cut_activate(self, *extra):
        widget = self.get_focus()
        if isinstance(widget, Gtk.Editable):
            widget.cut_clipboard()
        elif isinstance(widget, Gtk.TextView):
            widget.emit("cut-clipboard")

    def on_menu_paste_activate(self, *extra):
        widget = self.get_focus()
        if isinstance(widget, Gtk.Editable):
            widget.paste_clipboard()
        elif isinstance(widget, Gtk.TextView):
            widget.emit("paste-clipboard")

    def on_action_fullscreen_toggled(self, widget):
        window_state = self.get_window().get_state()
        is_full = window_state & Gdk.WindowState.FULLSCREEN
        if widget.get_active() and not is_full:
            self.fullscreen()
        elif is_full:
            self.unfullscreen()

    def on_menu_edit_down_activate(self, *args):
        self.current_doc().next_diff(Gdk.ScrollDirection.DOWN)

    def on_menu_edit_up_activate(self, *args):
        self.current_doc().next_diff(Gdk.ScrollDirection.UP)

    def on_open_external(self, *args):
        self.current_doc().open_external()

    def on_toolbar_stop_clicked(self, *args):
        self.current_doc().action_stop()

    def action_close_window(self, *extra):
        app = self.get_application()
        app.quit()

    def action_minimize_window(self, *extra):
        # self.get_window().iconify()  # Not working!
        # self.iconify() # Not working!!
        # window = NSApp.mainWindow()      # keyWindow isn't working either!
        # window.performMiniaturize_(window)  # Not working!!
        # window.miniaturize_(window) # Not working!!
        # NSApp.miniaturizeAll_(self) # Not working!!!
        #   After digging, it looks like a bug in GDK where GDK_QUARTZ_BORDERLESS_WINDOW is set for our Window
        #   and GDK_QUARTZ_MINIATURIZABLE_WINDOW is not being set.. All because of the GtkHeaderBar.. argh.
        #   I'll have to fix this in the gdk code inside gtk
        # self.get_window().hide() # Nope..
        pass # FIXME.. This is terribly annoyting.. Highest priority for next release..

    def action_maximize_window(self, *extra):
        window_state = self.get_window().get_state()
        is_max = window_state & Gdk.WindowState.MAXIMIZED
        get_icon = Gtk.Image.new_from_icon_name
        maximize_image = None
        if is_max:
            maximize_image = get_icon('window-maximize-symbolic', 1)
            self.get_window().unmaximize()
        else:
            maximize_image = get_icon('window-restore-symbolic', 1)
            self.get_window().maximize()
        print(self.maximize_button)
        # self.maximize_button.add(maximize_image)
        # FIXME: Figure out how gtk ui builder works and complete this

    def osx_menu_setup(self):       
        if self.quartz_ready == False:
            self.get_application().setup_mac_integration(self.menubar)
            self.quartz_ready = True

    def osx_bring_to_front(self):
        NSApp.setActivationPolicy_(NSApplicationActivationPolicyRegular)
        # NSApp.activateIgnoringOtherApps_(True)
        # NSApp.activateWithOptions_(NSApplicationActivateIgnoringOtherApps | NSApplicationActivateAllWindows)
        macapp = self.get_application()
            #gtkosx_application.Application()
        self.set_keep_above(True)
        self.set_keep_above(False)

        macapp.attention_request(gtkosx_application.ApplicationAttentionType.NFO_REQUEST)

    def osx_dock_bounce(self):
        macapp = self.get_application()
        macapp.attention_request(gtkosx_application.ApplicationAttentionType.NFO_REQUEST)

    def osx_toggle_fullscreen(self):
        # FIXME: Implement
        return
        # handle = self.get_window_handle_helper()
        # window = NSWindow.initWithWindowRef(handle) # Nope..
        # window.toggleFullScreen_(None)

    def _find_lib_path(self):
        # FIXME: Implement
        return ""

    def get_window_handle_helper(self):
        window = self.get_property('window')
        ctypes.pythonapi.PyCapsule_GetPointer.restype = ctypes.c_void_p
        ctypes.pythonapi.PyCapsule_GetPointer.argtypes = [ctypes.py_object]
        gpointer = ctypes.pythonapi.PyCapsule_GetPointer(window.__gpointer__, None)
        libgdk = ctypes.CDLL(self._find_lib_path() + "/libgdk-3.dylib")
        libgdk.gdk_quartz_window_get_nsview.restype = ctypes.c_void_p
        libgdk.gdk_quartz_window_get_nsview.argtypes = [ctypes.c_void_p]
        handle = libgdk.gdk_quartz_window_get_nsview(gpointer)
        return handle
