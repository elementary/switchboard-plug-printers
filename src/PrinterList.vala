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

public class Printers.PrinterList : Gtk.Grid {
    public signal void new_printer_page (Gtk.Widget widget);
    public signal void focused_printer_page (Gtk.Widget widget);

    Gtk.ListBox list_box;

    public PrinterList () {
        
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        expand = true;
        list_box = new Gtk.ListBox ();

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (list_box);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.width_request = 250;
        scrolled.expand = true;

        var toolbar = new Gtk.Toolbar ();
        toolbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        toolbar.icon_size = Gtk.IconSize.SMALL_TOOLBAR;
        var add_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        var remove_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        remove_button.sensitive = false;
        toolbar.add (add_button);
        toolbar.add (remove_button);
        add (scrolled);
        add (toolbar);

        list_box.row_selected.connect ((row) => {
            remove_button.sensitive = (row != null);
            if (row != null) {
                focused_printer_page (((PrinterRow) row).page);
            }
        });
    }

    public void add_printer (Printer printer) {
        var row = new PrinterRow (printer);
        list_box.add (row);
        new_printer_page (row.page);
        if (printer.is_default) {
            list_box.select_row (row);
        }
    }
}
