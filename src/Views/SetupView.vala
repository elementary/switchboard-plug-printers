// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015-2018 elementary LLC. (https://elementary.io)
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

public class Printers.OptionsPage : Gtk.Grid {
    public Printer printer { get; construct; }
    private int row_index = 2;

    public OptionsPage (Printer printer) {
        Object (printer: printer);
    }

    construct {
        var pages_per_sheet = new Gee.TreeSet<int> ();
        var default_page = printer.get_pages_per_sheet (pages_per_sheet);

        var pages_modebutton = new Printers.ModeButton ();

        if (pages_per_sheet.size == 1) {
            pages_modebutton.sensitive = false;
        }

        foreach (var page in pages_per_sheet) {
            var index = pages_modebutton.append_text ("%d".printf (page));
            if (page == default_page) {
                pages_modebutton.selected = index;
            }
        }

        pages_modebutton.mode_changed.connect ((w) => {
            var label = w as Gtk.Label;
            printer.set_default_pages (label.label);
        });

        var pages_label = new Gtk.Label (_("Pages per side:")) {
            xalign = 1
        };

        var sides = new Gee.TreeSet<string> ();
        var default_side = printer.get_sides (sides);

        var two_switch = new Gtk.Switch () {
            valign = Gtk.Align.CENTER
        };

        if (sides.size == 1) {
            two_switch.sensitive = false;
        }

        var switch_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        switch_box.append (two_switch);

        if (sides.size > 2) {
            var two_mode = new Printers.ModeButton () {
                hexpand = true
            };
            two_mode.append_text (dpgettext2 ("gtk30", "printing option value", "Long Edge (Standard)"));
            two_mode.append_text (dpgettext2 ("gtk30", "printing option value", "Short Edge (Flip)"));
            two_mode.selected = 0;

            two_switch.bind_property ("active", two_mode, "sensitive");

            switch_box.append (two_mode);

            switch (default_side) {
                case CUPS.Attributes.Sided.TWO_LONG_EDGE:
                    two_mode.selected = 0;
                    two_switch.active = true;
                    break;
                case CUPS.Attributes.Sided.TWO_SHORT_EDGE:
                    two_mode.selected = 1;
                    two_switch.active = true;
                    break;
                case CUPS.Attributes.Sided.ONE:
                    two_switch.active = false;
                    two_mode.sensitive = false;
                    break;
            }

            two_mode.notify["selected"].connect (() => {
                if (two_mode.selected == 0) {
                    printer.set_default_side (CUPS.Attributes.Sided.TWO_LONG_EDGE);
                } else {
                    printer.set_default_side (CUPS.Attributes.Sided.TWO_SHORT_EDGE);
                }
            });

            two_switch.notify["active"].connect (() => {
                if (two_switch.active) {
                    if (two_mode.selected == 0) {
                        printer.set_default_side (CUPS.Attributes.Sided.TWO_LONG_EDGE);
                    } else {
                        printer.set_default_side (CUPS.Attributes.Sided.TWO_SHORT_EDGE);
                    }
                } else {
                    printer.set_default_side (CUPS.Attributes.Sided.ONE);
                }
            });
        } else {
            two_switch.notify["active"].connect (() => {
                if (two_switch.active) {
                    printer.set_default_side (CUPS.Attributes.Sided.TWO_LONG_EDGE);
                } else {
                    printer.set_default_side (CUPS.Attributes.Sided.ONE);
                }
            });
        }

        var two_side_label = new Gtk.Label (_("Two-sided:")) {
            xalign = 1
        };

        column_spacing = 12;
        row_spacing = 12;
        attach (pages_label, 1, 0);
        attach (pages_modebutton, 2, 0);
        attach (two_side_label, 1, 1);
        attach (switch_box, 2, 1);

        var orientations = new Gee.TreeSet<int> ();
        var default_orientation = printer.get_orientations (orientations);
        if (orientations.size > 1) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var orientation in orientations) {
                switch (orientation) {
                    case CUPS.Attributes.Orientation.PORTRAIT:
                        combobox.append ("%d".printf (CUPS.Attributes.Orientation.PORTRAIT), dgettext ("gtk30", "Portrait"));
                        break;
                    case CUPS.Attributes.Orientation.LANDSCAPE:
                        combobox.append ("%d".printf (CUPS.Attributes.Orientation.LANDSCAPE), dgettext ("gtk30", "Landscape"));
                        break;
                    case CUPS.Attributes.Orientation.REVERSE_PORTRAIT:
                        combobox.append ("%d".printf (CUPS.Attributes.Orientation.REVERSE_PORTRAIT), dgettext ("gtk30", "Reverse portrait"));
                        break;
                    case CUPS.Attributes.Orientation.REVERSE_LANDSCAPE:
                        combobox.append ("%d".printf (CUPS.Attributes.Orientation.REVERSE_LANDSCAPE), dgettext ("gtk30", "Reverse landscape"));
                        break;
                }
            }

            combobox.set_active_id ("%d".printf (default_orientation));
            combobox.changed.connect (() => {
                printer.set_default_orientation (combobox.get_active_id ());
            });
            var label = new Gtk.Label (_("Orientation:")) {
                xalign = 1
            };
            attach (label, 1, row_index, 1, 1);
            attach (combobox, 2, row_index, 1, 1);
            row_index++;
        }

        var media_sizes = new Gee.TreeSet<string> ();
        var default_media_sizes = printer.get_media_sizes (media_sizes);
        if (media_sizes.size > 1) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var media_size in media_sizes) {
                var papersize = new Gtk.PaperSize (media_size);
                combobox.append (papersize.get_name (), papersize.get_display_name ());
            }

            combobox.set_active_id (default_media_sizes);
            combobox.changed.connect (() => {

            });
            var label = new Gtk.Label (_("Media Size:")) {
                xalign = 1
            };
            attach (label, 1, row_index, 1, 1);
            attach (combobox, 2, row_index, 1, 1);
            row_index++;
        }

        var print_color_modes = new Gee.TreeSet<string> ();
        var default_color_mode = printer.get_print_color_modes (print_color_modes);
        if (print_color_modes.size > 1) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var print_color_mode in print_color_modes) {
                switch (print_color_mode) {
                    case "auto":
                        combobox.append (print_color_mode, _("Automatic"));
                        break;
                    case "bi-level":
                        combobox.append (print_color_mode, _("One Color"));
                        break;
                    case "color":
                        combobox.append (print_color_mode, _("Color"));
                        break;
                    case "highlight":
                        combobox.append (print_color_mode, _("One Color + Black"));
                        break;
                    case "monochrome":
                        combobox.append (print_color_mode, _("Greyscale"));
                        break;
                    case "process-bi-level":
                        combobox.append (print_color_mode, _("Processed Color"));
                        break;
                    case "process-monochrome":
                        combobox.append (print_color_mode, _("Processed Greyscale"));
                        break;
                }
            }

            combobox.set_active_id (default_color_mode);
            combobox.changed.connect (() => {
                printer.set_default_print_color_mode (combobox.get_active_id ());
            });
            var label = new Gtk.Label (_("Color mode:")) {
                xalign = 1
            };
            attach (label, 1, row_index, 1, 1);
            attach (combobox, 2, row_index, 1, 1);
            row_index++;
        }

        var output_bins = new Gee.TreeSet<string> ();
        var default_output_bin = printer.get_output_bins (output_bins);
        if (output_bins.size > 1) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var output_bin in output_bins) {
                switch (output_bin) {
                    case "top":
                        combobox.append (output_bin, dgettext ("gtk30", "Top Bin"));
                        break;
                    case "middle":
                        combobox.append (output_bin, dgettext ("gtk30", "Middle Bin"));
                        break;
                    case "bottom":
                        combobox.append (output_bin, dgettext ("gtk30", "Bottom Bin"));
                        break;
                    case "side":
                        combobox.append (output_bin, dgettext ("gtk30", "Side Bin"));
                        break;
                    case "left":
                        combobox.append (output_bin, dgettext ("gtk30", "Left Bin"));
                        break;
                    case "right":
                        combobox.append (output_bin, dgettext ("gtk30", "Right Bin"));
                        break;
                    case "center":
                        combobox.append (output_bin, dgettext ("gtk30", "Center Bin"));
                        break;
                    case "rear":
                        combobox.append (output_bin, dgettext ("gtk30", "Rear Bin"));
                        break;
                    case "face-up":
                        combobox.append (output_bin, dgettext ("gtk30", "Face Up Bin"));
                        break;
                    case "face-down":
                        combobox.append (output_bin, dgettext ("gtk30", "Face Down Bin"));
                        break;
                    case "large-capacity":
                        combobox.append (output_bin, dgettext ("gtk30", "Large Capacity Bin"));
                        break;
                    case "my-mailbox":
                        combobox.append (output_bin, dgettext ("gtk30", "My Mailbox"));
                        break;
                    default:
                        if ("stacker-" in output_bin) {
                            int number = int.parse (output_bin.replace ("stacker-", ""));
                            combobox.append (output_bin, dgettext ("gtk30", "Stacker %d").printf (number));
                        } else if ("mailbox-" in output_bin) {
                            int number = int.parse (output_bin.replace ("mailbox-", ""));
                            combobox.append (output_bin, dgettext ("gtk30", "Mailbox %d").printf (number));
                        } else if ("tray-" in output_bin) {
                            int number = int.parse (output_bin.replace ("tray-", ""));
                            combobox.append (output_bin, dgettext ("gtk30", "Tray %d").printf (number));
                        } else {
                            combobox.append (output_bin, output_bin);
                        }

                        break;
                }
            }

            combobox.set_active_id (default_output_bin);
            combobox.changed.connect (() => {
                printer.set_default_output_bin (combobox.get_active_id ());
            });
            var label = new Gtk.Label (_("Output Tray:")) {
                xalign = 1
            };
            attach (label, 1, row_index, 1, 1);
            attach (combobox, 2, row_index, 1, 1);
            row_index++;
        }

        var print_qualities = new Gee.TreeSet<int> ();
        var default_print_quality = printer.get_print_qualities (print_qualities);
        if (print_qualities.size > 1) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var print_quality in print_qualities) {
                switch (print_quality) {
                    case 3:
                        combobox.append ("%d".printf (print_quality), _("Draft"));
                        break;
                    case 4:
                        combobox.append ("%d".printf (print_quality), _("Normal"));
                        break;
                    case 5:
                        combobox.append ("%d".printf (print_quality), _("High"));
                        break;
                }
            }

            combobox.set_active_id ("%d".printf (default_print_quality));
            var label = new Gtk.Label (_("Quality:")) {
                xalign = 1
            };
            attach (label, 1, row_index, 1, 1);
            attach (combobox, 2, row_index, 1, 1);
            row_index++;
        }

        var media_sources = new Gee.TreeSet<string> ();
        var default_media_source = printer.get_media_sources (media_sources);
        if (media_sources.size > 1) {
            var combobox = new Gtk.ComboBoxText ();
            foreach (var media_source in media_sources) {
                switch (media_source) {
                    case "alloc-paper":
                        combobox.append (media_source, _("Paper Allocation"));
                        break;
                    case "alternate":
                        combobox.append (media_source, _("Alternate Tray"));
                        break;
                    case "alternate-roll":
                        combobox.append (media_source, _("Alternate Roll"));
                        break;
                    case "auto":
                        combobox.append (media_source, _("Automatic"));
                        break;
                    case "bottom":
                        combobox.append (media_source, _("Bottom"));
                        break;
                    case "by-pass-tray":
                        combobox.append (media_source, _("By-pass Tray"));
                        break;
                    case "center":
                        combobox.append (media_source, _("Center"));
                        break;
                    case "continuous":
                        combobox.append (media_source, _("Continuous Autofeed"));
                        break;
                    case "cd":
                    case "disk":
                        combobox.append (media_source, _("Disk"));
                        break;
                    case "envelope":
                        combobox.append (media_source, _("Envelope"));
                        break;
                    case "hagaki":
                        combobox.append (media_source, _("Hagaki"));
                        break;
                    case "large-capacity":
                        combobox.append (media_source, _("Large Capacity"));
                        break;
                    case "left":
                        combobox.append (media_source, _("Left"));
                        break;
                    case "main":
                        combobox.append (media_source, _("Main Tray"));
                        break;
                    case "main-roll":
                        combobox.append (media_source, _("Main Roll"));
                        break;
                    case "manual":
                        combobox.append (media_source, _("Manual"));
                        break;
                    case "middle":
                        combobox.append (media_source, _("Middle"));
                        break;
                    case "photo":
                        combobox.append (media_source, _("Photo"));
                        break;
                    case "asf":
                    case "rear":
                        combobox.append (media_source, _("Rear"));
                        break;
                    case "right":
                        combobox.append (media_source, _("Right"));
                        break;
                    case "side":
                        combobox.append (media_source, _("Side"));
                        break;
                    case "top":
                        combobox.append (media_source, _("Top"));
                        break;
                    default:
                        if ("roll-" in media_source) {
                            int number = int.parse (media_source.replace ("roll-", ""));
                            combobox.append (media_source, _("Roll %d").printf (number));
                        } else if ("tray-" in media_source) {
                            int number = int.parse (media_source.replace ("tray-", ""));
                            combobox.append (media_source, _("Tray %d").printf (number));
                        } else {
                            combobox.append (media_source, media_source);
                        }

                        break;
                }
            }

            combobox.set_active_id (default_media_source);
            combobox.changed.connect (() => {
                printer.set_default_media_source (combobox.get_active_id ());
            });
            var label = new Gtk.Label (_("Paper Source:")) {
                xalign = 1
            };
            attach (label, 1, row_index, 1, 1);
            attach (combobox, 2, row_index, 1, 1);
            row_index++;
        }

        printer.get_all ();
    }
}
