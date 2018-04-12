// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015 Pantheon Developers (https://launchpad.net/switchboard-plug-printers)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

namespace Printers {

    public class Plug : Switchboard.Plug {
        private Gtk.Paned main_paned;
        private Gtk.Stack main_stack;
        private PrinterList list;

        public Plug () {
            var settings = new Gee.TreeMap<string, string?> (null, null);
            settings.set ("printer", null);
            Object (category: Category.HARDWARE,
                    code_name: "pantheon-printers",
                    display_name: _("Printers"),
                    description: _("Configure printers, manage print queues, and view ink levels"),
                    icon: "printer",
                    supported_settings: settings);
        }

        public override Gtk.Widget get_widget () {
            if (main_paned == null) {
                var stack = new Gtk.Stack ();
                stack.visible = true;

                list = new PrinterList (stack);

                var empty_alert = new Granite.Widgets.AlertView (
                    _("No Printers Available"),
                    _("Connect to a printer by clicking the icon in the toolbar below."),
                    "printer-error"
                );
                empty_alert.visible = true;
                empty_alert.get_style_context ().remove_class (Gtk.STYLE_CLASS_VIEW);

                main_stack = new Gtk.Stack ();
                main_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
                main_stack.add_named (empty_alert, "empty-alert");
                main_stack.add_named (stack, "main-paned");

                main_paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
                main_paned.pack1 (list, false, false);
                main_paned.pack2 (main_stack, true, false);
                main_paned.show_all ();

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
