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

public class Printers.InkLevel : Gtk.FlowBox {
    public unowned Printer printer { get; construct; }
    private const string STYLE_CLASS =
    """
    block.filled {
        background-color: #%s;
    }
    """;

    public InkLevel (Printer printer) {
        Object (printer: printer);
    }

    construct {
        homogeneous = true;
        column_spacing = 12;
        row_spacing = 24;
        max_children_per_line = 30;

        // var colors = printer.get_color_levels ();

        var cyan = new Printer.ColorLevel () {
            color = "#00ffff",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Imaging Unit (Cyan)"
        };

        var cyana = new Printer.ColorLevel () {
            color = "#00ffff",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Toner (Cyan)"
        };

        var cyanc = new Printer.ColorLevel () {
            color = "#FF00FF",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Imaging Unit (Magenta)"
        };

        var cyand = new Printer.ColorLevel () {
            color = "#FF00FF",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Toner (Magenta)"
        };

        var cyane = new Printer.ColorLevel () {
            color = "#FFFF00",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Imaging Unit (Yellow)"
        };

        var cyanf = new Printer.ColorLevel () {
            color = "#FFFF00",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Toner (Yellow)"
        };

        var cyang = new Printer.ColorLevel () {
            color = "#000000",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Toner (Black)"
        };

        var cyanh = new Printer.ColorLevel () {
            color = "#000000",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Drum Cartridge"
        };

        var cyani = new Printer.ColorLevel () {
            color = "#000000",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Developer Cartridge"
        };

        var cyanj = new Printer.ColorLevel () {
            color = "cyan",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Waste Toner Box"
        };

        var cyank = new Printer.ColorLevel () {
            color = "cyan",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Fusing Unit"
        };

        var cyanl = new Printer.ColorLevel () {
            color = "cyan",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Image Transfer Belt Unit"
        };

        var cyanm = new Printer.ColorLevel () {
            color = "cyan",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Transfer Roller Unit"
        };

        var cyann = new Printer.ColorLevel () {
            color = "cyan",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Ozone Filter"
        };

        var cyano = new Printer.ColorLevel () {
            color = "cyan",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Toner Filter"
        };

        var cyanp = new Printer.ColorLevel () {
            color = "cyan",
            level = 5,
            level_max = 10,
            level_min = 0,
            name = "Staple Cartridge"
        };

        var colors = new Gee.ArrayList<Printer.ColorLevel> ();
        colors.add (cyan);
        colors.add (cyana);
        colors.add (cyanc);
        colors.add (cyand);
        colors.add (cyane);
        colors.add (cyanf);
        colors.add (cyang);
        colors.add (cyanh);
        colors.add (cyani);
        colors.add (cyanj);
        colors.add (cyank);
        colors.add (cyanl);
        colors.add (cyanm);
        colors.add (cyann);
        colors.add (cyano);
        colors.add (cyanp);

        var size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.VERTICAL);

        foreach (Printer.ColorLevel color in colors) {
            string[] colors_codes = { null, "3689E6" };
            if ("#" in color.color) {
                colors_codes = color.color.split ("#");
            }

            var ink_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);

            for (int i = 1; i < colors_codes.length; i++) {
                var css_color = STYLE_CLASS.printf (colors_codes[i]);

                var level = new Gtk.LevelBar.for_interval (color.level_min, color.level_max) {
                    height_request = 128,
                    hexpand = true,
                    vexpand = true,
                    inverted = true,
                    orientation = Gtk.Orientation.VERTICAL,
                    value = color.level
                };

                var provider = new Gtk.CssProvider ();
                try {
                    provider.load_from_data (css_color, css_color.length);
                    level.get_style_context ().add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                } catch (Error e) {
                    warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, css_color);
                }

                ink_box.add (level);
            }

            var label = new Gtk.Label (get_translated_name (color.name ?? "black")) {
                justify = Gtk.Justification.CENTER,
                wrap = true,
                max_width_chars = 10,
                yalign = 0
            };

            var color_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            color_box.add (ink_box);
            color_box.add (label);

            size_group.add_widget (label);

            add (color_box);
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
