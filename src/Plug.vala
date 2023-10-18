/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2015-2023 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

namespace Printers {

    public class Plug : Switchboard.Plug {
        private Gtk.Paned main_paned;
        private Gtk.Stack main_stack;
        private PrinterList list;

        public Plug () {
            GLib.Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.LOCALEDIR);
            GLib.Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");

            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("printer", null);
            Object (category: Category.HARDWARE,
                    code_name: "io.elementary.switchboard.printers",
                    display_name: _("Printers"),
                    description: _("Configure printers, manage print queues, and view ink levels"),
                    icon: "printer",
                    supported_settings: settings);
        }

        public override Gtk.Widget get_widget () {
            if (main_paned == null) {
                var stack = new Gtk.Stack () {
                    visible = true
                };

                list = new PrinterList (stack);

                var empty_alert = new Granite.Placeholder (_("No Printers Available")) {
                    description = _("Connect to a printer by clicking the icon in the toolbar below."),
                    icon = new ThemedIcon ("printer-error"),
                    visible = true
                };
                empty_alert.remove_css_class (Granite.STYLE_CLASS_VIEW);

                main_stack = new Gtk.Stack () {
                    transition_type = Gtk.StackTransitionType.CROSSFADE
                };
                main_stack.add_named (empty_alert, "empty-alert");
                main_stack.add_named (stack, "main-paned");

                main_paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL) {
                    start_child = list,
                    resize_start_child = false,
                    shrink_start_child = false,
                    end_child = main_stack,
                    resize_end_child = true,
                    shrink_end_child = false
                };

                update_alert_visible ();

                list.notify["has-child"].connect (() => {
                    update_alert_visible ();
                });
            }

            return main_paned;
        }

        private void update_alert_visible () {
            if (list.has_child) {
                main_stack.visible_child_name = "main-paned";
            } else {
                main_stack.visible_child_name = "empty-alert";
            }
        }

        public override void shown () {

        }

        public override void hidden () {

        }

        public override void search_callback (string location) {

        }

        // 'search' returns results like ("Keyboard → Behavior → Duration", "keyboard<sep>behavior")
        public override async Gee.TreeMap<string, string> search (string search) {
            return new Gee.TreeMap<string, string> (null, null);
        }
    }
}

public Switchboard.Plug get_plug (Module module) {
    debug ("Activating Printers plug");
    var plug = new Printers.Plug ();
    return plug;
}
