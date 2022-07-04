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

public class Printers.PrinterList : Gtk.Grid {
    public signal void new_printer_page (Gtk.Widget widget);

    public Gtk.Stack stack { get; construct; }
    public bool has_child { get; private set; default=false; }

    Gtk.ListBox list_box;
    private Printers.AddDialog? add_dialog = null;

    public PrinterList (Gtk.Stack stack) {
        Object (stack: stack);
    }

    construct {
        hexpand = true;
        vexpand = true;
        list_box = new Gtk.ListBox ();

        var scrolled = new Gtk.ScrolledWindow () {
            child = list_box,
            hscrollbar_policy = Gtk.PolicyType.NEVER,
            width_request = 250,
            hexpand = true,
            vexpand = true
        };

        var actionbar = new Gtk.ActionBar ();
        actionbar.add_css_class (Granite.STYLE_CLASS_FLAT);

        var add_button_label = new Gtk.Label (_("Add Printer…"));
        var add_button_image = new Gtk.Image.from_icon_name ("list-add-symbolic") {
            halign = Gtk.Align.START,
            pixel_size = 16
        };

        var add_button_indicator_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        add_button_indicator_box.append (add_button_image);
        add_button_indicator_box.append (add_button_label);

        var add_button = new Gtk.Button () {
            margin_top = 3,
            margin_bottom = 3,
            child = add_button_indicator_box
        };
        add_button.add_css_class (Granite.STYLE_CLASS_FLAT);

        actionbar.pack_start (add_button);
        attach (scrolled, 0, 0);
        attach (actionbar, 0, 1);

        list_box.row_selected.connect ((row) => {
            if (row != null) {
                stack.set_visible_child (((PrinterRow) row).page);
            }
        });

        add_button.clicked.connect (() => {
            if (add_dialog == null) {
                add_dialog = new Printers.AddDialog ();
                add_dialog.transient_for = (Gtk.Window) get_root ();
                add_dialog.present ();

                add_dialog.close.connect (() => {
                    add_dialog = null;
                });
            }

            add_dialog.present ();
        });

        unowned PrinterManager manager = PrinterManager.get_default ();
        foreach (var printer in manager.get_printers ()) {
            add_printer (printer);
        }

        manager.printer_added.connect ((printer) => add_printer (printer));
    }

    public void add_printer (Printer printer) {
        var row = new PrinterRow (printer);
        list_box.append (row);
        stack.add_child (row.page);
        if (printer.is_default) {
            list_box.select_row (row);
        }

        has_child = true;
        row.destroy.connect (() => {
            uint i = 0;
            var children = list_box.observe_children ();
            for (var index = 0; index < children.get_n_items (); index++) {
                if ((PrinterRow) children.get_item (index) != row) {
                    i++;
                }
            }

            has_child = i > 0;
        });
    }
}
