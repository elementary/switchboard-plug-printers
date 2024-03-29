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

    class construct {
        set_css_name ("settingssidebar");
    }

    construct {
        var headerbar = new Adw.HeaderBar () {
            show_end_title_buttons = false,
            show_title = false
        };

        list_box = new Gtk.ListBox ();

        var scrolled = new Gtk.ScrolledWindow () {
            child = list_box,
            hscrollbar_policy = NEVER,
            hexpand = true,
            vexpand = true
        };

        var add_button_box = new Gtk.Box (HORIZONTAL, 0);
        add_button_box.append (new Gtk.Image.from_icon_name ("list-add-symbolic"));
        add_button_box.append (new Gtk.Label (_("Add Printer…")));

        var add_button = new Gtk.Button () {
            child = add_button_box,
            has_frame = false
        };

        var actionbar = new Gtk.ActionBar ();
        actionbar.pack_start (add_button);

        var toolbarview = new Adw.ToolbarView () {
            content = scrolled,
            top_bar_style = FLAT,
            bottom_bar_style = RAISED
        };
        toolbarview.add_top_bar (headerbar);
        toolbarview.add_bottom_bar (actionbar);

        append (toolbarview);
        add_css_class (Granite.STYLE_CLASS_SIDEBAR);

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
            list_box.remove (row);
            has_child = list_box.get_row_at_index (0) != null;
        });
    }
}
