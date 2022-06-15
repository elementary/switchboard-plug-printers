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
        orientation = Gtk.Orientation.VERTICAL;
        expand = true;
        list_box = new Gtk.ListBox ();

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (list_box);
        scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scrolled.width_request = 250;
        scrolled.expand = true;

        var actionbar = new Gtk.ActionBar ();
        actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        var add_button = new Gtk.Button.with_label (_("Add Printer…")) {
            always_show_image = true,
            image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR),
            margin = 3
        };
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        actionbar.add (add_button);
        add (scrolled);
        add (actionbar);

        list_box.row_selected.connect ((row) => {
            // remove_button.sensitive = (row != null);
            if (row != null) {
                stack.set_visible_child (((PrinterRow) row).page);
            }
        });

        add_button.clicked.connect (() => {
            if (add_dialog == null) {
                add_dialog = new Printers.AddDialog ();
                add_dialog.transient_for = (Gtk.Window) get_toplevel ();
                add_dialog.show_all ();

                add_dialog.destroy.connect (() => {
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
        list_box.add (row);
        stack.add (row.page);
        if (printer.is_default) {
            list_box.select_row (row);
        }

        has_child = true;
        row.destroy.connect (() => {
            uint i = 0;
            list_box.get_children ().foreach ((child) => {
                if (child != row) {
                    i++;
                }
            });

            has_child = i > 0;
        });
    }
}
