/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2015-2023 elementary, Inc. (https://elementary.io)
 *
 * Authored by: Corentin Noël <corentin@elementary.io>
 */

public class Printers.SuppliesView: Gtk.Box {
    public Printer printer { get; construct; }

    private const string STYLE_CLASS =
    """
    levelbar.color-%s block.filled {
        background-color: #%s;
    }
    """;

    public SuppliesView (Printer printer) {
        Object (printer: printer);
    }

    construct {
        var name_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = _("BrandPrinter X3000")
        };

        var name_label = new Granite.HeaderLabel (_("Description")) {
            mnemonic_widget = name_entry
        };

        var location_entry = new Gtk.Entry () {
            placeholder_text = _("Lab 1 or John's Desk")
        };

        var location_label = new Granite.HeaderLabel (_("Location")) {
            margin_top = 9,
            mnemonic_widget = location_entry
        };

        var ink_flowbox = new Gtk.FlowBox () {
            column_spacing = 12,
            homogeneous = true,
            margin_top = 21,
            max_children_per_line = 30,
            row_spacing = 24
        };

        orientation = VERTICAL;
        spacing = 3;
        append (name_label);
        append (name_entry);
        append (location_label);
        append (location_entry);
        append (ink_flowbox);

        printer.bind_property ("info", name_entry, "text", BIDIRECTIONAL | SYNC_CREATE);
        printer.bind_property ("location", location_entry, "text", BIDIRECTIONAL | SYNC_CREATE);

        var colors = printer.get_color_levels ();

        var size_group = new Gtk.SizeGroup (VERTICAL);

        foreach (Printer.ColorLevel color in colors) {
            string[] colors_codes = { null, "3689E6" };
            if ("#" in color.color) {
                colors_codes = color.color.split ("#");
            }

            var ink_box = new Gtk.Box (HORIZONTAL, 3);

            for (int i = 1; i < colors_codes.length; i++) {
                var css_color = STYLE_CLASS.printf (colors_codes[i], colors_codes[i]);

                var level = new Gtk.LevelBar.for_interval (color.level_min, color.level_max) {
                    height_request = 64,
                    hexpand = true,
                    vexpand = true,
                    inverted = true,
                    orientation = VERTICAL,
                    value = color.level
                };
                level.add_css_class ("color-" + colors_codes[i]);

                var provider = new Gtk.CssProvider ();
                try {
                    provider.load_from_data (css_color.data);
                    Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                } catch (Error e) {
                    warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, css_color);
                }

                ink_box.append (level);
            }

            var label = new Gtk.Label (get_translated_name (color.name ?? "black")) {
                justify = CENTER,
                wrap = true,
                max_width_chars = 10,
                yalign = 0
            };

            var color_box = new Gtk.Box (VERTICAL, 6);
            color_box.append (ink_box);
            color_box.append (label);

            size_group.add_widget (label);

            ink_flowbox.append (color_box);
        }
    }

    private unowned string get_translated_name (string name) {
        switch (name) {
            case "black(PGBK)":
            case "Black(PGBK)":
                return _("Black (PGBK)");
            case "black(BK)":
            case "Black(BK)":
                return _("Black (BK)");
            case "black":
            case "black ink":
            case "Black":
                return _("Black");
            case "yellow":
            case "yellow ink":
            case "Yellow":
                return _("Yellow");
            case "cyan":
            case "cyan ink":
            case "Cyan":
                return _("Cyan");
            case "magenta":
            case "magenta ink":
            case "Magenta":
                return _("Magenta");
            case "tri-color ink":
                return _("Tri-color");
        }

        return name;
    }
}
