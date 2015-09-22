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

public class Printers.EditableTitle : Gtk.EventBox {
    private Printer printer;

    public EditableTitle (Printer printer) {
        this.printer = printer;
        valign = Gtk.Align.CENTER;
        events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
        events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;
        var name = new Gtk.Label (printer.info);
        name.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) name).xalign = 0;
        name.get_style_context ().add_class ("h2");

        var edit_button = new Gtk.ToggleButton ();
        edit_button.image = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU);
        edit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        var button_revealer = new Gtk.Revealer ();
        button_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        button_revealer.add (edit_button);
        var button_grid = new Gtk.Grid ();
        button_grid.valign = Gtk.Align.CENTER;
        button_grid.add (button_revealer);

        var grid = new Gtk.Grid ();
        grid.valign = Gtk.Align.CENTER;
        grid.column_spacing = 12;
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.add (name);
        grid.add (button_grid);
        add (grid);

        enter_notify_event.connect ((event) => {
            if (event.detail != Gdk.NotifyType.INFERIOR) {
                button_revealer.set_reveal_child (true);
            }

            return false;
        });

        leave_notify_event.connect ((event) => {
            if (event.detail != Gdk.NotifyType.INFERIOR) {
                button_revealer.set_reveal_child (false);
            }

            return false;
        });
    }
}
