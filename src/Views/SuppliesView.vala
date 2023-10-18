/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2015-2023 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Printers.SuppliesView: Gtk.Widget {
    public Printer printer { get; construct; }

    public SuppliesView (Printer printer) {
        Object (printer: printer);
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    construct {
        var name_label = new Gtk.Label (_("Description:")) {
            xalign = 1
        };

        var name_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = _("BrandPrinter X3000"),
            text = printer.info
        };
        name_entry.bind_property ("text", printer, "info", GLib.BindingFlags.BIDIRECTIONAL);

        var location_label = new Gtk.Label (_("Location:")) {
            xalign = 1
        };

        var location_entry = new Gtk.Entry () {
            text = printer.location,
            placeholder_text = _("Lab 1 or John's Desk")
        };
        location_entry.bind_property ("text", printer, "location", GLib.BindingFlags.BIDIRECTIONAL);

        var default_label = new Gtk.Label (_("Use as default printer:"));

        var default_switch = new Gtk.Switch () {
            active = printer.is_default,
            halign = Gtk.Align.START,
            valign = Gtk.Align.CENTER
        };
        default_switch.bind_property ("active", printer, "is-default", GLib.BindingFlags.BIDIRECTIONAL);

        var ink_level = new InkLevel (printer) {
            margin_top = 12
        };

        var grid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 12
        };
        grid.attach (name_label, 0, 0);
        grid.attach (name_entry, 1, 0);
        grid.attach (location_label, 0, 1);
        grid.attach (location_entry, 1, 1);
        grid.attach (default_label, 0, 2);
        grid.attach (default_switch, 1, 2);
        grid.attach (ink_level, 0, 3, 2, 1);

        var scrolled = new Gtk.ScrolledWindow () {
            child = grid
        };
        scrolled.set_parent (this);
    }

    ~SuppliesView () {
        while (get_last_child () != null) {
            get_last_child ().unparent ();
        }
    }
}
