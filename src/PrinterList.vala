/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2015-2023 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Printers.PrinterList : Gtk.Box {
    public signal void new_printer_page (Gtk.Widget widget);

    public Gtk.Stack stack { get; construct; }
    public bool has_child { get; private set; default = false; }

    private Gtk.ListBox list_box;

    public PrinterList (Gtk.Stack stack) {
        Object (stack: stack);
    }

    construct {
        orientation = Gtk.Orientation.VERTICAL;
        hexpand = true;
        vexpand = true;

        list_box = new Gtk.ListBox ();

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            child = list_box,
            hscrollbar_policy = NEVER,
            width_request = 250,
            hexpand = true,
            vexpand = true
        };

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.add (new Gtk.Image.from_icon_name ("list-add-symbolic", BUTTON));
        add_button_box.add (new Gtk.Label (_("Add Printer…")));

        var add_button = new Gtk.Button () {
            child = add_button_box,
            margin_top = 3,
            margin_bottom = 3
        };
        add_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var actionbar = new Gtk.ActionBar ();
        actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        actionbar.add (add_button);

        add (scrolled);
        add (actionbar);

        list_box.row_selected.connect ((row) => {
            if (row != null) {
                stack.set_visible_child (((PrinterRow) row).page);
            }
        });

        add_button.clicked.connect (() => {
            var add_dialog = new Printers.AddDialog () {
                modal = true,
                transient_for = (Gtk.Window) get_toplevel ()
            };

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
