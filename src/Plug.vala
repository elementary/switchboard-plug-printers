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
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

namespace Printers {

    public static Plug plug;

    public class Plug : Switchboard.Plug {
        Gtk.Paned main_paned;
        Cups.Notifier notifier;

        public Plug () {
            Object (category: Category.HARDWARE,
                    code_name: Build.PLUGCODENAME,
                    display_name: _("Printers"),
                    description: _("Change printers settings"),
                    icon: "printer");
            plug = this;
        }

        public override Gtk.Widget get_widget () {
            if (main_paned == null) {
                main_paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
                var list_box = new Gtk.ListBox ();
                var scrolled = new Gtk.ScrolledWindow (null, null);
                scrolled.add (list_box);
                scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
                var stack = new Gtk.Stack ();
                main_paned.pack1 (scrolled, false, false);
                main_paned.pack2 (stack, true, false);
                unowned CUPS.Destination[] dests = CUPS.get_destinations ();
                foreach (unowned CUPS.Destination dest in dests) {
                    var printer = new Printer (dest);
                    var row = new PrinterRow (printer);
                    list_box.add (row);
                    stack.add (row.page);
                }

                try {
                    notifier = Bus.get_proxy_sync (BusType.SYSTEM, "org.cups.cupsd.Notifier",
                                                                      "/org/cups/cupsd/Notifier");
                    notifier.printer_state_changed.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => {
                        warning (text);
                    });
                    notifier.printer_modified.connect ((text, printer_uri, name, state, state_reasons, is_accepting_jobs) => {
                        warning (text);
                    });
                    notifier.server_stopped.connect ((str) => {
                        warning (str);
                    });
                    notifier.server_restarted.connect ((str) => {
                        warning (str);
                    });
                    notifier.server_started.connect ((str) => {
                        warning (str);
                    });
                } catch (IOError e) {
                    critical (e.message);
                }

                main_paned.show_all ();
            }

            return main_paned;
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
