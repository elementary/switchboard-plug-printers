/*-
 * Copyright 2015-2022 elementary, Inc.
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

public class Printers.InkLevel : Gtk.Widget {
    public unowned Printer printer { get; construct; }
    private const string STYLE_CLASS =
    """
    levelbar.%s block.filled {
        background-color: #%s;
    }
    """;

    public InkLevel (Printer printer) {
        Object (printer: printer);
    }

    static construct {
        set_layout_manager_type (typeof (Gtk.BinLayout));
    }

    construct {
        var colors = printer.get_color_levels ();

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.VERTICAL);

        var flowbox = new Gtk.FlowBox () {
            homogeneous = true,
            column_spacing = 12,
            row_spacing = 24,
            max_children_per_line = 30
        };
        flowbox.set_parent (this);

        foreach (Printer.ColorLevel color in colors) {
            string[] colors_codes = { null, "3689E6" };
            if ("#" in color.color) {
                colors_codes = color.color.split ("#");
            }

            var ink_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);

            for (int i = 1; i < colors_codes.length; i++) {
                var style_class = color.name + "%i".printf (i);
                var css_color = STYLE_CLASS.printf (style_class, colors_codes[i]);

                var level = new Gtk.LevelBar.for_interval (color.level_min, color.level_max) {
                    height_request = 64,
                    hexpand = true,
                    vexpand = true,
                    inverted = true,
                    orientation = Gtk.Orientation.VERTICAL,
                    value = color.level
                };
                level.add_css_class (style_class);

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
                justify = Gtk.Justification.CENTER,
                wrap = true,
                max_width_chars = 10,
                yalign = 0
            };

            var color_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            color_box.append (ink_box);
            color_box.append (label);

            size_group.add_widget (label);

            flowbox.append (color_box);
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

    ~InkLevel () {
        while (this.get_last_child () != null) {
            this.get_last_child ().unparent ();
        }
    }
}
