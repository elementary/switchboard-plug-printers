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
        list_box.add_css_class (Granite.STYLE_CLASS_RICH_LIST);

        var scrolled = new Gtk.ScrolledWindow () {
            child = list_box,
            hscrollbar_policy = NEVER,
            width_request = 250,
            hexpand = true,
            vexpand = true
        };

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("list-add-symbolic"));
        add_button_box.append (new Gtk.Label (_("Add Printer…")));

        var add_button = new Gtk.Button () {
            child = add_button_box,
            has_frame = false,
            margin_top = 3,
            margin_bottom = 3
        };

        var actionbar = new Gtk.ActionBar ();
        actionbar.add_css_class (Granite.STYLE_CLASS_FLAT);
        actionbar.pack_start (add_button);

        append (scrolled);
        append (actionbar);

        list_box.row_selected.connect ((row) => {
            if (row != null) {
                stack.set_visible_child (((PrinterRow) row).page);
            }
        });

        add_button.clicked.connect (() => {
            var add_dialog = new Printers.AddDialog () {
                modal = true,
                transient_for = (Gtk.Window) get_root ()
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
        list_box.append (row);
        stack.add_child (row.page);
        if (printer.is_default) {
            list_box.select_row (row);
        }

        has_child = true;
        row.destroy.connect (() => {
            has_child = list_box.get_row_at_index (0) != null;
        });
    }
}
