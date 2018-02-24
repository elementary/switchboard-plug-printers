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
        Gtk.Stack main_stack;
        private Printers.AddPopover add_popover;

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
            if (main_stack == null) {
                main_stack = new Gtk.Stack ();
                var main_paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
                var stack = new Gtk.Stack ();
                var list = new PrinterList (stack);
                main_paned.pack1 (list, false, false);
                main_paned.pack2 (stack, true, false);

                var welcome = new Granite.Widgets.Welcome (_("No Printers"), _("Add a printer to begin printing"));
                var add_index = welcome.append ("printer-new", _("Add Printer"), _("Search for the printer you need"));
                welcome.activated.connect (() => {
                    var widget = welcome.get_button_from_index (add_index);
                    if (add_popover != null) {
                        if (add_popover.visible) {
                            return;
                        } else {
                            add_popover.destroy ();
                        }
                    }

                    add_popover = new Printers.AddPopover (widget);
                    add_popover.show_all ();
                });

                main_stack.add (welcome);
                main_stack.add (main_paned);
                main_stack.show_all ();
                main_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

                list.notify["has-child"].connect (() => {
                    if (list.has_child) {
                        main_stack.set_visible_child (main_paned);
                    } else {
                        main_stack.set_visible_child (welcome);
                    }
                });

                if (list.has_child) {
                    main_stack.set_visible_child (main_paned);
                } else {
                    main_stack.set_visible_child (welcome);
                }
            }

            return main_stack;
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
