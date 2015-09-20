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

public class Printers.OptionsPage : Gtk.Grid {
    private Printer printer;

    public OptionsPage (Printer printer) {
        this.printer = printer;
        expand = true;
        margin = 12;
        column_spacing = 12;
        row_spacing = 6;

        build_pages_per_sheet ();
        build_two_sided ();
        build_orientation ();
        build_page_size ();
    }

    private void build_pages_per_sheet () {
        var pages_per_sheet = new Gee.TreeSet<int> ();
        var default_page = printer.get_pages_per_sheet (pages_per_sheet);
        if (pages_per_sheet.size > 1) {
            var box = new Granite.Widgets.ModeButton ();
            foreach (var page in pages_per_sheet) {
                var index = box.append_text ("%d".printf (page));
                if (page == default_page) {
                    box.selected = index;
                }
            }

            var label = new Gtk.Label (_("Pages per Sheet:"));
            label.hexpand = true;
            ((Gtk.Misc) label).xalign = 1;
            attach (label, 0, 0, 1, 1);
            attach (box, 1, 0, 1, 1);
        }
    }

    private void build_two_sided () {
        var sides = new Gee.TreeSet<string> ();
        var default_side = printer.get_sides (sides);
        if (sides.size > 1) {
            var grid = new Gtk.Grid ();
            grid.orientation = Gtk.Orientation.HORIZONTAL;
            var two_switch = new Gtk.Switch ();
            var switch_grid = new Gtk.Grid ();
            switch_grid.add (two_switch);
            switch_grid.valign = Gtk.Align.CENTER;
            grid.add (switch_grid);

            if (sides.size > 2) {
                var two_mode = new Granite.Widgets.ModeButton ();
                two_switch.bind_property ("active", two_mode, "sensitive");
                grid.add (two_mode);
                var index = two_mode.append_text (_("Long Edge (Standard)"));
                if (default_side == CUPS.Attributes.Sided.TWO_LONG_EDGE) {
                    two_mode.selected = index;
                }

                index = two_mode.append_text (_("Short Edge (Flip)"));
                if (default_side == CUPS.Attributes.Sided.TWO_SHORT_EDGE) {
                    two_mode.selected = index;
                }

                if (default_side == CUPS.Attributes.Sided.ONE) {
                    two_mode.sensitive = false;
                }
            }

            var label = new Gtk.Label (_("Two sided:"));
            label.hexpand = true;
            ((Gtk.Misc) label).xalign = 1;
            attach (label, 0, 1, 1, 1);
            attach (grid, 1, 1, 1, 1);
        }
    }

    private void build_orientation () {
        var orientations = new Gee.TreeSet<int> ();
        var default_orientation = printer.get_orientations (orientations);
        if (orientations.size > 1) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var orientation in orientations) {
                switch (orientation) {
                    case CUPS.Attributes.Orientation.PORTRAIT:
                        combobox.append ("%d".printf (CUPS.Attributes.Orientation.PORTRAIT), _("Portrait"));
                        break;
                    case CUPS.Attributes.Orientation.LANDSCAPE:
                        combobox.append ("%d".printf (CUPS.Attributes.Orientation.LANDSCAPE), _("Landcape"));
                        break;
                    case CUPS.Attributes.Orientation.REVERSE_PORTRAIT:
                        combobox.append ("%d".printf (CUPS.Attributes.Orientation.REVERSE_PORTRAIT), _("Reverse Portrait"));
                        break;
                    case CUPS.Attributes.Orientation.REVERSE_LANDSCAPE:
                        combobox.append ("%d".printf (CUPS.Attributes.Orientation.REVERSE_LANDSCAPE), _("Reverse Landcape"));
                        break;
                }
            }

            combobox.set_active_id ("%d".printf (default_orientation));
            var label = new Gtk.Label (_("Orientation:"));
            label.hexpand = true;
            ((Gtk.Misc) label).xalign = 1;
            attach (label, 0, 2, 1, 1);
            attach (combobox, 1, 2, 1, 1);
        }
    }

    private void build_page_size () {
        //int default_attribute = 4;
        /*unowned CUPS.IPP.Attribute attr = result.find_attribute (CUPS.Attributes.MEDIA_DEFAULT, CUPS.IPP.Tag.ZERO);
        if (attr.get_count () > 0) {
            warning (attr.get_string (0));*/
            /*default_attribute = attr.get_integer (0);
            if (default_attribute < 0) {
                default_attribute = 4;
            }*/
            /*MediaSize *media_size;
            GList     *media_iter;
            GList     *media_size_iter;
            gchar     *media;

            for (media_iter = cups_printer->media_supported,
                media_size_iter = cups_printer->media_size_supported;
                media_size_iter != NULL;
                media_iter = media_iter->next,
                media_size_iter = media_size_iter->next)
            {
                media = (gchar *) media_iter->data;
                media_size = (MediaSize *) media_size_iter->data;

                page_setup = create_page_setup_from_media (media,
                                                           media_size,
                                                           cups_printer->media_margin_default_set,
                                                           cups_printer->media_bottom_margin_default,
                                                           cups_printer->media_top_margin_default,
                                                           cups_printer->media_left_margin_default,
                                                           cups_printer->media_right_margin_default);

                result = g_list_prepend (result, page_setup);
            }*/
        //}

        /*var combobox = new Gtk.ComboBoxText ();
        attr = result.find_attribute (CUPS.Attributes.MEDIA_SIZE_SUPPORTED, CUPS.IPP.Tag.ZERO);
        var paper_sizes = new Gee.LinkedList<Array<double?>> ();
        for (int i = 0; i < attr.get_count (); i++) {
            var size = new Array<double?> ();
            unowned CUPS.IPP.IPP media_size_collection = attr.get_collection (i);
            size.append_val (media_size_collection.find_attribute ("x-dimension", CUPS.IPP.Tag.INTEGER).get_integer (0) / 100.0);
            size.append_val (media_size_collection.find_attribute ("y-dimension", CUPS.IPP.Tag.INTEGER).get_integer (0) / 100.0);
            if (size.index (0) != (-1 / 100.0) && size.index (1) != (-1 / 100.0)) {
                paper_sizes.add (size);
            }
        }

        attr = result.find_attribute (CUPS.Attributes.MEDIA_SUPPORTED, CUPS.IPP.Tag.ZERO);
        var media_supported = new Gee.LinkedList<string> ();
        for (int i = 0; i < attr.get_count (); i++) {
            media_supported.add (attr.get_string (i));
        }

        if (attr.get_count () > 1) {
            var label = new Gtk.Label (_("Page Size:"));
            label.hexpand = true;
            ((Gtk.Misc) label).xalign = 1;
            attach (label, 0, 3, 1, 1);
            attach (combobox, 1, 3, 1, 1);
        }*/
    }
}
