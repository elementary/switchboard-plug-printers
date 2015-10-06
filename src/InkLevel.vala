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

public class Printers.InkLevel : Gtk.Grid {
    private Printer printer;
    private Gee.ArrayList<ColorLevel> colors;
    private const string STYLE_CLASS =
    """@define-color levelbar_color %s;
    .coloredlevelbar.fill-block {
        background-color: @levelbar_color;

        border: 1px solid shade (@levelbar_color, 0.90);
        border-radius: 2.5px;
        box-shadow: inset 0 0 0 1px alpha (#fff, 0.05),
                    inset 0 1px 0 0 alpha (#fff, 0.35),
                    inset 0 -1px 0 0 alpha (#fff, 0.15),
                    0 1px 0 0 alpha (@bg_highlight_color, 0.15);
        transition: all 100ms ease-in;
        background-image: linear-gradient(to bottom,
                                      shade (@levelbar_color, 1.30),
                                      @levelbar_color);
    }
    .coloredlevelbar.fill-block.empty-fill-block {
        background-color: shade (@bg_color, 0.95);
        background-image: linear-gradient(to bottom,
                                      shade (@bg_color, 0.95),
                                      shade (@bg_color, 0.85)
                                      );

        border-color: alpha (#000, 0.25);
        box-shadow: inset 0 0 0 1px alpha (@bg_highlight_color, 0.05),
                    inset 0 1px 0 0 alpha (@bg_highlight_color, 0.45),
                    inset 0 -1px 0 0 alpha (@bg_highlight_color, 0.15),
                    0 1px 0 0 alpha (@bg_highlight_color, 0.15);
    }
    """;

    public InkLevel (Printer printer) {
        orientation = Gtk.Orientation.HORIZONTAL;
        height_request = 100;
        column_spacing = 6;
        colors = new Gee.ArrayList<ColorLevel> ();
        this.printer = printer;
        populate_values ();
        foreach (var color in colors) {
            var level = new Gtk.LevelBar.for_interval (color.level_min, color.level_max);
            level.orientation = Gtk.Orientation.VERTICAL;
            level.value = color.level;
            level.inverted = true;
            level.tooltip_text = get_translated_name (color.name);
            level.expand = true;
            var context = level.get_style_context ();
            context.add_class ("coloredlevelbar");
            var css_color = STYLE_CLASS.printf (color.color);
            var provider = new Gtk.CssProvider ();
            try {
                provider.load_from_data (css_color, css_color.length);
                context.add_provider (provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            } catch (Error e) {
                warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, css_color);
            }

            add (level);
        }
    }

    private string get_translated_name (string name) {
        switch (name) {
            case "black(PGBK)":
            case "Black(PGBK)":
                return _("Black (PGBK)");
            case "black(BK)":
            case "Black(BK)":
                return _("Black (BK)");
            case "black":
            case "Black":
                return _("Black");
            case "yellow":
            case "Yellow":
                return _("Yellow");
            case "cyan":
            case "Cyan":
                return _("Cyan");
            case "magenta":
            case "Magenta":
                return _("Magenta");
        }

        return name;
    }

    private void populate_values () {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", printer.dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        string[] attributes = { "marker-colors",
                                "marker-levels",
                                "marker-names",
                                "marker-high-levels",
                                "marker-low-levels" };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute ("marker-colors", CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                var color = new ColorLevel ();
                color.color = attr.get_string (i);
                colors.add (color);
            }

            attr = request.find_attribute ("marker-levels", CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                colors.get (i).level = attr.get_integer (i);
            }

            attr = request.find_attribute ("marker-high-levels", CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                colors.get (i).level_max = attr.get_integer (i);
            }

            attr = request.find_attribute ("marker-low-levels", CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                colors.get (i).level_min = attr.get_integer (i);
            }

            attr = request.find_attribute ("marker-names", CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                colors.get (i).name = attr.get_string (i);
            }
        } else {
            critical ("Error: %s", request.get_status_code ().to_string ());
        }

        colors.sort ((a, b) => {
            Gdk.RGBA col_a = {}, col_b = {};
            col_a.parse (a.color);
            col_b.parse (b.color);

            if (col_a.green > 0.8 && col_a.blue > 0.8 && col_a.red < 0.3)
                return -1;

            if (col_b.green > 0.8 && col_b.blue > 0.8 && col_b.red < 0.3)
                return 1;

            if (col_a.green < 0.3 && col_a.blue > 0.8 && col_a.red > 0.8)
                return -1;

            if (col_b.green < 0.3 && col_b.blue > 0.8 && col_b.red > 0.8)
                return 1;

            if (col_a.green > 0.8 && col_a.blue < 0.3 && col_a.red > 0.8)
                return -1;

            if (col_b.green > 0.8 && col_b.blue < 0.3 && col_b.red > 0.8)
                return 1;

            var a_tot = col_a.green + col_a.blue + col_a.red;
            var b_tot = col_b.green + col_b.blue + col_b.red;
            if (a_tot > b_tot) {
                return 1;
            } else if (a_tot == b_tot) {
                return 0;
            } else {
                return -1;
            }
        });
    }
    
    public class ColorLevel : GLib.Object {
        public int level = 0;
        public int level_max = 0;
        public int level_min = 0;
        public string color = null;
        public string name = null;

        public ColorLevel () {
        
        }
    }
}
