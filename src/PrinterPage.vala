// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2015-2016 elementary LLC.
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

public class Printers.PrinterPage : Gtk.Grid {
    private unowned Printer printer;

    public PrinterPage (Printer printer) {
        this.printer = printer;
        expand = true;
        margin = 12;
        column_spacing = 12;
        row_spacing = 6;
        var stack = new Gtk.Stack ();
        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.halign = Gtk.Align.CENTER;
        stack_switcher.set_stack (stack);
        stack.add_titled (new JobsView (printer), "general", _("General"));
        stack.add_titled (new OptionsPage (printer), "options", _("Options"));
        create_header ();
        attach (stack_switcher, 0, 1, 3, 1);
        attach (stack, 0, 2, 3, 1);
        show_all ();

    }

    private void create_header () {
        var image = new Gtk.Image.from_icon_name ("printer", Gtk.IconSize.DIALOG);

        var editable_title = new EditableTitle (printer.info);
        editable_title.get_style_context ().add_class ("h2");
        editable_title.title_edited.connect ((new_title) => {
            printer.info = new_title;
        });

        var expander = new Gtk.Grid ();
        expander.hexpand = true;

        var info_button = new Gtk.ToggleButton ();
        info_button.image = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.MENU);
        info_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var enable_switch = new Gtk.Switch ();
        enable_switch.active = printer.state != "5" && printer.is_accepting_jobs;
        enable_switch.notify["active"].connect (() => {
            printer.enabled = enable_switch.active;
        });

        var right_grid = new Gtk.Grid ();
        right_grid.column_spacing = 12;
        right_grid.orientation = Gtk.Orientation.HORIZONTAL;
        right_grid.valign = Gtk.Align.CENTER;
        right_grid.add (expander);
        right_grid.add (info_button);
        right_grid.add (enable_switch);

        var info_popover = new Gtk.Popover (info_button);

        info_button.toggled.connect (() => {
            if (info_button.active == true) {
                info_popover.show_all ();
            } else {
                info_popover.hide ();
            }
        });

        attach (image, 0, 0, 1, 1);
        attach (editable_title, 1, 0, 1, 1);
        attach (right_grid, 2, 0, 1, 1);

        var location_label = new Gtk.Label (_("Location:"));
        ((Gtk.Misc) location_label).xalign = 1;
        location_label.hexpand = true;

        var location_entry = new Gtk.Entry ();
        location_entry.text = printer.location ?? "";
        location_entry.hexpand = true;
        location_entry.halign = Gtk.Align.START;
        location_entry.placeholder_text = _("Lab 1 or John's Desk");
        location_entry.activate.connect (() => {
            printer.location = location_entry.text;
        });

        var ink_level = new InkLevel (printer);

        var default_check = new Gtk.ModelButton ();
        default_check.text = _("Use as Default Printer");
        default_check.role = Gtk.ButtonRole.CHECK;

        default_check.active = printer.is_default;
        default_check.notify["active"].connect (() => {
            if (default_check.active) {
                printer.is_default = true;
            } else {
                default_check.active = true;
            }
        });

        var print_test = new Gtk.ModelButton ();
        print_test.text = _("Print Test Page");
        print_test.clicked.connect (() => print_test_page ());

        info_popover.hide.connect (() => {
            info_button.active = false;
            location_entry.text = printer.location ?? "";
        });

        var info_grid = new Gtk.Grid ();
        info_grid.margin = 12;
        info_grid.column_spacing = 12;
        info_grid.row_spacing = 12;
        info_grid.attach (location_label, 0, 0, 1, 1);
        info_grid.attach (location_entry, 1, 0, 1, 1);
        info_grid.attach (ink_level, 0, 2, 2, 1);

        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_bottom = 3;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_grid.row_spacing = 3;
        menu_grid.add (info_grid);
        menu_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        menu_grid.add (default_check);
        menu_grid.add (print_test);

        info_popover.add (menu_grid);
    }

    private string? get_testprint_filename (string datadir) {
        string[] testprints = {"/data/testprint", "/data/testprint.ps"};
        foreach (var testprint in testprints) {
            string filename = datadir + testprint;
            if (Posix.access (filename, Posix.R_OK) == 0) {
                return filename;
            }
        }

        return null;
    }

    private void print_test_page () {
        string? filename = null;
        var datadir = GLib.Environment.get_variable ("CUPS_DATADIR");
        if (datadir != null) {
            filename = get_testprint_filename (datadir);
        } else {
            string[] dirs = { "/usr/share/cups", "/usr/local/share/cups" };
            foreach (var dir in dirs) {
                filename = get_testprint_filename (dir);
                if (filename != null) {
                    break;
                }
            }
        }

        if (filename != null) {
            var type = int.parse (printer.printer_type);
            string printer_uri, resource;
            if (CUPS.PrinterType.CLASS in type) {
                printer_uri = "ipp://localhost/classes/%s".printf (printer.dest.name);
                resource = "/classes/%s".printf (printer.dest.name);
            } else {
                printer_uri = "ipp://localhost/printers/%s".printf (printer.dest.name);
                resource = "/printers/%s".printf (printer.dest.name);
            }

            var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.PRINT_JOB);
            request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, printer_uri);
            request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.NAME, "requesting-user-name", null, CUPS.get_user ());
            /// TRANSLATORS: Name of the test page job
            request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.NAME, "job-name", null, _("Test page"));
            request.do_file_request (CUPS.HTTP.DEFAULT, resource, filename);
        }
    }
}
