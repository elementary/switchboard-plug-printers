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

public class Printers.PrinterPage : Granite.SimpleSettingsPage {
    public unowned Printer printer { get; construct; }

    public PrinterPage (Printer printer) {
        Object (
            activatable: true,
            icon_name: "printer",
            title: printer.info,
            description: printer.location,
            printer: printer
        );
    }

    construct {
        var stack = new Gtk.Stack ();
        var jobs_view = new JobsView (printer);
        stack.add_titled (jobs_view, "general", _("Print Queue"));
        stack.add_titled (new OptionsPage (printer), "options", _("Page Setup"));
        stack.add_titled (new SuppliesView (printer), "supplies", _("Settings & Supplies"));

        var stack_switcher = new Gtk.StackSwitcher ();
        stack_switcher.halign = Gtk.Align.CENTER;
        stack_switcher.homogeneous = true;
        stack_switcher.stack = stack;

        content_area.row_spacing = 24;
        content_area.attach (stack_switcher, 0, 1);
        content_area.attach (stack, 0, 2);

        var print_test = new Gtk.Button.with_label (_("Print Test Page"));
        print_test.clicked.connect (() => print_test_page ());

        action_area.add (print_test);

        printer.bind_property ("info", this, "title");
        printer.bind_property ("location", this, "description");

        status_switch.active = printer.is_enabled;
        print_test.sensitive = status_switch.active;

        status_switch.bind_property ("active", printer, "is-enabled", BindingFlags.DEFAULT);
        status_switch.bind_property ("active", print_test, "sensitive", BindingFlags.DEFAULT);

        show_all ();
    }

    private string? get_testprint_filename (string datadir, bool boring) {
        //  Boring test page
        string page;
        if (boring) {
            page = "testprint";
        } else {
            //  Random selection from fun ones
            string[] fun_pages = {
                "sudoku-testprint",
                //  "fortune-testprint"
            };
            page = fun_pages[GLib.Random.int_range (0, fun_pages.length)];
        }

        string[] testprints = {"/data/" + page, "/data/" + page + ".ps"};
        foreach (var testprint in testprints) {
            string filename = datadir + testprint;
            if (Posix.access (filename, Posix.R_OK) == 0) {
                return filename;
            }
        }

        return null;
    }

    private void print_test_page () {

        // Ask the user if they want a fun test page
        var dialog = new Granite.MessageDialog.with_image_from_icon_name (
            _("Do you want a practical or fun test page?"),
            "",
            "dialog-information",
            Gtk.ButtonsType.CANCEL
        );

        //  TODO make function
        var checkbox = new Gtk.CheckButton.with_label (_("Remember my choice"));
        checkbox.show ();

        dialog.custom_bin.add (checkbox);

        dialog.add_button (_("Boring"), 1);
        dialog.add_button (_("Fun!"), 2);

        dialog.show_all ();
        dialog.response.connect ((response_id) => {

            bool boring_page;

            switch (response_id) {
                case 1:
                    boring_page = true;
                    break;
                case 2:
                    boring_page = false;
                    break;
                default:
                    dialog.destroy ();
                    return;
            }

            string? filename = null;
            var datadir = GLib.Environment.get_variable ("CUPS_DATADIR");
            if (datadir != null) {
                filename = get_testprint_filename (datadir, boring_page);
            } else {
                string[] dirs = { "/usr/share/cups", "/usr/local/share/cups" };
                foreach (var dir in dirs) {
                    filename = get_testprint_filename (dir, boring_page);
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

            dialog.destroy ();
        });
    }
}
