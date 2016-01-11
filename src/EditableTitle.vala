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
    public signal void title_edited (string new_title);
    private Gtk.Label title;
    private Gtk.Entry entry;
    private Gtk.Stack stack;
    private Gtk.Grid grid;

    public EditableTitle (string? title_name) {
        valign = Gtk.Align.CENTER;
        events |= Gdk.EventMask.ENTER_NOTIFY_MASK;
        events |= Gdk.EventMask.LEAVE_NOTIFY_MASK;

        title = new Gtk.Label (title_name);
        title.ellipsize = Pango.EllipsizeMode.END;
        ((Gtk.Misc) title).xalign = 0;

        var edit_button = new Gtk.Button ();
        edit_button.image = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.MENU);
        edit_button.tooltip_text = _("Edit");
        edit_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        var button_revealer = new Gtk.Revealer ();
        button_revealer.valign = Gtk.Align.CENTER;
        button_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        button_revealer.add (edit_button);

        grid = new Gtk.Grid ();
        grid.valign = Gtk.Align.CENTER;
        grid.column_spacing = 12;
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.add (title);
        grid.add (button_revealer);

        entry = new Gtk.Entry ();
        entry.secondary_icon_name = "go-jump-symbolic";
        entry.secondary_icon_tooltip_text = _("Edit");

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        stack.add (grid);
        stack.add (entry);
        add (stack);

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

        edit_button.clicked.connect (() => {
            entry.text = title.label;
            stack.set_visible_child (entry);
        });

        entry.activate.connect (() => validate ());
        entry.icon_release.connect ((p0, p1) => {
            if (p0 == Gtk.EntryIconPosition.SECONDARY) {
                validate ();
            }
        });
    }

    public void set_title (string new_title) {
        title.label = new_title;
    }

    private void validate () {
        if (entry.text.strip () != "" && title.label != entry.text) {
            title.label = entry.text;
            title_edited (entry.text);
        }
        stack.set_visible_child (grid);
    }
}
