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
        Gtk.Grid main_grid;

        public Plug () {
            Object (category: Category.HARDWARE,
                    code_name: Build.PLUGCODENAME,
                    display_name: _("Printers"),
                    description: _("Change printers settings"),
                    icon: "printer");
            plug = this;
        }

        public override Gtk.Widget get_widget () {
            if (main_grid == null) {
                main_grid = new Gtk.Grid ();
                var hello_label = new Gtk.Label (_("Hello World"));
                main_grid.attach (hello_label, 0, 0, 1, 1);
                main_grid.show_all ();
            }

            return main_grid;
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
