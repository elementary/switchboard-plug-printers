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

// Here because there are some default device_info values so it's nice to have them translated
namespace Printers.Translations {
    private static void translations () {
        /// Tranlators: This is a protocol name, please keep the (https).
        _("Internet Printing Protocol (https)");
        /// Tranlators: This is a protocol name, please keep the (http).
        _("Internet Printing Protocol (http)");
        /// Tranlators: This is a protocol name, please keep the (ipp).
        _("Internet Printing Protocol (ipp)");
        /// Tranlators: This is a protocol name, please keep the (ipps).
        _("Internet Printing Protocol (ipps)");
        /// Tranlators: This is a protocol name, please keep the (ipp14).
        _("Internet Printing Protocol (ipp14)");
        /// Tranlators: This is a protocol name.
        _("LPD/LPR Host or Printer");
        /// Tranlators: This is a protocol name.
        _("AppSocket/HP JetDirect");
    }
}

public class Printers.AddDialog : Hdy.Window {
    private Granite.ValidatedEntry connection_entry;
    private Granite.ValidatedEntry description_entry;
    private Gtk.Button add_printer_button;
    private Gtk.Button refresh_button;
    private Gtk.Stack stack;
    private Granite.Widgets.AlertView alertview;
    private Gtk.Stack drivers_stack;
    private Gee.LinkedList<Printers.DeviceDriver> drivers;
    private Gtk.ListBox driver_view;
    private Gtk.ListStore make_list_store;
    private Gtk.TreeView make_view;
    private Gtk.ListBox devices_list;
    private Printers.DeviceDriver selected_driver = null;
    private Cancellable driver_cancellable;

    public AddDialog () {
        search_device.begin ();
    }

    construct {
        var spinner = new Gtk.Spinner () {
            halign = CENTER,
            valign = CENTER
        };
        spinner.start ();

        var loading_label = new Gtk.Label (_("Finding nearby printers…"));

        var loading_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = CENTER,
            valign = CENTER
        };
        loading_box.add (loading_label);
        loading_box.add (spinner);
        loading_box.show_all ();

        devices_list = new Gtk.ListBox () {
            hexpand = true,
            vexpand = true
        };
        devices_list.set_placeholder (loading_box);
        devices_list.set_header_func ((Gtk.ListBoxUpdateHeaderFunc) temp_device_list_header);
        devices_list.set_sort_func ((Gtk.ListBoxSortFunc) temp_device_list_sort);

        var scrolled = new Gtk.ScrolledWindow (null, null) {
            child = devices_list
        };

        var frame = new Gtk.Frame (null) {
            child = scrolled
        };

        refresh_button = new Gtk.Button.with_label (_("Refresh")) {
            sensitive = false
        };

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        var next_button = new Gtk.Button.with_label (_("Next")) {
            sensitive = false
        };
        next_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var button_box = new Gtk.Box (HORIZONTAL, 6);
        button_box.add (refresh_button);
        button_box.add (new Gtk.Grid () { hexpand = true });
        button_box.add (cancel_button);
        button_box.add (next_button);

        var size_group = new Gtk.SizeGroup (HORIZONTAL);
        size_group.add_widget (refresh_button);
        size_group.add_widget (cancel_button);
        size_group.add_widget (next_button);

        var devices_box = new Gtk.Box (VERTICAL, 24) {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
        devices_box.add (frame);
        devices_box.add (button_box);

        alertview = new Granite.Widgets.AlertView (_("Impossible to list all available printers"), "", "dialog-error");
        alertview.no_show_all = true;

        stack = new Gtk.Stack () {
            transition_type = SLIDE_LEFT_RIGHT
        };
        stack.add_named (devices_box, "devices-grid");
        stack.add (alertview);

        default_height = 450;
        default_width = 500;
        child = stack;
        type_hint = DIALOG;
        show_all ();

        drivers = new Gee.LinkedList<Printers.DeviceDriver> ();

        devices_list.row_selected.connect ((row) => {
            next_button.sensitive = (row != null);
        });

        cancel_button.clicked.connect (() => {
            destroy ();
        });

        next_button.clicked.connect (() => {
            continue_with_tempdevice (((TempDeviceRow) devices_list.get_selected_row ()).temp_device);
        });

        refresh_button.clicked.connect (() => {
            refresh_button.sensitive = false;
            foreach (var row in devices_list.get_children ()) {
                devices_list.remove (row);
            }

            search_device.begin ();
        });
    }

    private async void search_device () {
        try {
            string error;
            GLib.HashTable<string, string> devices;
            yield Cups.get_pk_helper ().devices_get (CUPS.TIMEOUT_DEFAULT, -1, {}, {}, out error, out devices);
            if (error != null) {
                var tempdevices = new Gee.HashMap<int, Printers.TempDevice> (null, null);
                devices.foreach ((key, val) => {
                    var key_vars = key.split (":", 2);
                    int number = int.parse (key_vars[1]);
                    Printers.TempDevice tempdevice;
                    tempdevice = tempdevices.get (number);
                    if (tempdevice == null) {
                        tempdevice = new Printers.TempDevice ();
                        tempdevices.set (number, tempdevice);
                    }

                    switch (key_vars[0]) {
                        case "device-make-and-model":
                            if (val != "Unknown") {
                                tempdevice.device_make_and_model = val;
                            }
                            break;
                        case "device-class":
                            if (val == "network" && tempdevice.device_uri != null && ":" in tempdevice.device_uri) {
                                tempdevice.device_class = "ok-network";
                            } else {
                                tempdevice.device_class = val;
                            }

                            break;
                        case "device-uri":
                            tempdevice.device_uri = val;
                            if (tempdevice.device_class != null && tempdevice.device_class == "network" && ":" in tempdevice.device_uri) {
                                tempdevice.device_class = "ok-network";
                            }
                            break;
                        case "device-info":
                            tempdevice.device_info = _(val);
                            break;
                        case "device-id":
                            tempdevice.device_id = val;
                            break;
                        default:
                            debug ("missing: %s => %s", key_vars[0], val);
                            break;
                    }
                });

                process_devices (tempdevices.values);
            } else {
                show_error (error);
            }
        } catch (Error e) {
            show_error (e.message);
        }
    }

    // Once devices are available.
    private void process_devices (Gee.Collection<Printers.TempDevice> tempdevices) {
        foreach (var tempdevice in tempdevices) {
            devices_list.add (new TempDeviceRow (tempdevice));
        }

        devices_list.show_all ();
        refresh_button.sensitive = true;
    }

    // Shows the error panel
    private void show_error (string error) {
        alertview.no_show_all = false;
        alertview.show_all ();
        stack.set_visible_child (alertview);
        alertview.description = error;
    }

    // Shows the next panel with further configuration
    private void continue_with_tempdevice (TempDevice temp_device) {
        connection_entry = new Granite.ValidatedEntry () {
            hexpand = true,
            placeholder_text = "ipp://hostname/ipp/port1"
        };

        var connection_label = new Granite.HeaderLabel (_("Connection")) {
            mnemonic_widget =  connection_entry
        };

        var connection_error = new ErrorRevealer (
            _("Connection uri must contain “://“")
        ) {
            margin_top = 3
        };
        connection_error.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        description_entry = new Granite.ValidatedEntry () {
            hexpand = true,
            min_length = 1,
            placeholder_text = _("BrandPrinter X3000"),
            text = temp_device.get_model_from_id () ?? ""
        };

        var description_label = new Granite.HeaderLabel (_("Description")) {
            mnemonic_widget = description_entry
        };

        var description_error = new ErrorRevealer (
            _("Description cannot be empty")
        ) {
            margin_top = 3
        };
        description_error.get_style_context ().add_class (Gtk.STYLE_CLASS_ERROR);

        var location_entry = new Gtk.Entry () {
            hexpand = true,
            placeholder_text = _("Lab 1 or John's desk")
        };

        var location_label = new Granite.HeaderLabel (_("Location")) {
            mnemonic_widget = location_entry
        };

        var spinner = new Gtk.Spinner () {
            halign = CENTER,
            valign = CENTER
        };
        spinner.start ();

        make_list_store = new Gtk.ListStore (1, typeof (string));

        var cellrenderer = new Gtk.CellRendererText () {
            xpad = 6
        };

        make_view = new Gtk.TreeView.with_model (make_list_store) {
            headers_visible = false
        };
        make_view.get_selection ().mode = Gtk.SelectionMode.BROWSE;
        make_view.insert_column_with_attributes (-1, null, cellrenderer, "text", 0);

        var make_scrolled = new Gtk.ScrolledWindow (null, null) {
            child = make_view,
            hscrollbar_policy = NEVER
        };

        driver_view = new Gtk.ListBox ();
        driver_view.set_placeholder (new Gtk.Label (_("Loading…")));

        var driver_scrolled = new Gtk.ScrolledWindow (null, null) {
            child = driver_view,
            hscrollbar_policy = NEVER,
            hexpand = true,
            vexpand = true
        };

        var drivers_paned = new Gtk.Paned (HORIZONTAL);
        drivers_paned.pack1 (make_scrolled, false, false);
        drivers_paned.pack2 (driver_scrolled, true, false);

        drivers_stack = new Gtk.Stack () {
            transition_type = CROSSFADE,
            hexpand = true,
            vexpand = true
        };
        drivers_stack.add_named (spinner, "loading");
        drivers_stack.add_named (drivers_paned, "drivers");
        drivers_stack.show_all ();

        var frame = new Gtk.Frame (null) {
            child = drivers_stack,
            margin_top = 12,
            margin_bottom = 24
        };

        driver_cancellable = new Cancellable ();
        fetch_ppds (temp_device);

        var previous_button = new Gtk.Button.with_label (_("Back"));

        var cancel_button = new Gtk.Button.with_label (_("Cancel"));

        add_printer_button = new Gtk.Button.with_label (_("Add Printer")) {
            sensitive = false
        };
        add_printer_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        var button_box = new Gtk.Box (HORIZONTAL, 6) {
            halign = END,
            homogeneous = true
        };
        button_box.add (previous_button);
        button_box.add (cancel_button);
        button_box.add (add_printer_button);

        var device_box = new Gtk.Box (VERTICAL, 0) {
            margin_top = 12,
            margin_end = 12,
            margin_bottom = 12,
            margin_start = 12
        };
        device_box.add (description_label);
        device_box.add (description_entry);
        device_box.add (description_error);

        if (!(":" in temp_device.device_uri)) {
            connection_entry.changed.connect (() => {
                connection_entry.is_valid = connection_entry.text.contains ("://");
                connection_error.reveal_child = !connection_entry.is_valid;
                validate_form ();
            });

            connection_entry.text = temp_device.device_uri;
            device_box.add (connection_label);
            device_box.add (connection_entry);
            device_box.add (connection_error);
        }

        device_box.add (location_label);
        device_box.add (location_entry);
        device_box.add (frame);
        device_box.add (button_box);
        device_box.show_all ();

        stack.add (device_box);
        stack.set_visible_child (device_box);

        previous_button.clicked.connect (() => {
            driver_cancellable.cancel ();
            stack.visible_child_name = "devices-grid";
            device_box.destroy ();
        });

        cancel_button.clicked.connect (() => {
            destroy ();
        });

        add_printer_button.clicked.connect (() => {
            try {
                var name = temp_device.device_info.replace (" ", "_");
                name = name.replace ("/", "_");
                name = name.replace ("#", "_");
                var uri = temp_device.device_uri;
                if (connection_entry.parent != null) {
                    uri = connection_entry.text;
                }

                var pk_helper = Cups.get_pk_helper ();
                pk_helper.printer_add (name, uri, selected_driver.ppd_name, description_entry.text, location_entry.text);
                pk_helper.printer_set_enabled (name, true);
                pk_helper.printer_set_accept_jobs (name, true);
            } catch (Error e) {
                critical (e.message);
            }

            destroy ();
        });

        driver_view.row_selected.connect ((row) => {
            if (row != null) {
                selected_driver = ((DriverRow)row).driver;
                validate_form ();
            } else {
                add_printer_button.sensitive = false;
                selected_driver = null;
            }
        });

        description_entry.changed.connect (validate_form);
        description_entry.bind_property (
            "is-valid", description_error, "reveal-child", INVERT_BOOLEAN | SYNC_CREATE
        );
    }

    private void validate_form () {
        bool can_go_next = true;
        can_go_next &= connection_entry.parent == null || connection_entry.is_valid;
        can_go_next &= selected_driver != null;
        can_go_next &= description_entry.is_valid;

        add_printer_button.sensitive = can_go_next;
    }

    // Retreives all the drivers from the CUPS server.
    private void fetch_ppds (TempDevice temp_device) {
        new Thread<void*> (null, () => {
            char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
            CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, null);
            var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.CUPS_GET_PPDS);
            request.do_request (CUPS.HTTP.DEFAULT);

            if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
                unowned CUPS.IPP.Attribute attr = request.first_attribute ();
                var driver = new Printers.DeviceDriver ();
                while (attr != null) {
                    if (attr.get_name () == null) {
                        drivers.add (driver);
                        driver = null;
                        attr = request.next_attribute ();
                        continue;
                    }

                    if (driver == null) {
                        driver = new Printers.DeviceDriver ();
                    }

                    switch (attr.get_name ()) {
                        case "ppd-name":
                            driver.ppd_name = attr.get_string ();
                            break;
                        case "ppd-natural-language":
                            driver.ppd_natural_language = attr.get_string ();
                            break;
                        case "ppd-make":
                            driver.ppd_make = attr.get_string ();
                            break;
                        case "ppd-make-and-model":
                            driver.ppd_make_and_model = attr.get_string ();
                            break;
                        case "ppd-device-id":
                            driver.ppd_device_id = attr.get_string ();
                            break;
                        case "ppd-product":
                            driver.ppd_product = attr.get_string ();
                            break;
                        case "ppd-psversion":
                            driver.ppd_psversion = attr.get_string ();
                            break;
                        case "ppd-type":
                            driver.ppd_type = attr.get_string ();
                            break;
                        case "ppd-model-number":
                            driver.ppd_model_number = attr.get_integer ();
                            break;
                    }

                    attr = request.next_attribute ();
                }
            } else {
                critical ("Error: %s", request.get_status_code ().to_string ());
                return null;
            }

            Idle.add (() => {
                if (!driver_cancellable.is_cancelled ()) {
                    drivers_loaded (temp_device);
                }
                return GLib.Source.REMOVE;
            });

            return null;
        });
    }

    // Once drivers are available.
    private void drivers_loaded (TempDevice temp_device) {
        var make_list = new Gee.TreeSet<string> ();
        foreach (var driver in drivers) {
            make_list.add (driver.ppd_make);

            if (driver_cancellable.is_cancelled ()) {
                return;
            }
        }

        var make_selection = make_view.get_selection ();
        var current_make = temp_device.get_make_from_id ();
        foreach (var make in make_list) {
            Gtk.TreeIter iter;
            make_list_store.append (out iter);
            make_list_store.set (iter, 0, make);
            if (current_make != null && make == current_make) {
                make_selection.select_iter (iter);
                make_view.scroll_to_cell (make_list_store.get_path (iter), null, true, 0.0f, 0.0f);
                populate_driver_list_from_make (make, temp_device.get_model_from_id ());
            }

            if (driver_cancellable.is_cancelled ()) {
                return;
            }
        }

        if (make_selection.count_selected_rows () < 1) {
            Gtk.TreeIter iter;
            make_list_store.get_iter_first (out iter);
            make_selection.select_iter (iter);
            var val = GLib.Value (typeof (string));
            make_list_store.get_value (iter, 0, out val);
            populate_driver_list_from_make (val.get_string ());
        }

        make_selection.changed.connect_after (() => {
            Gtk.TreeModel model;
            Gtk.TreeIter iter;
            if (make_selection.get_selected (out model, out iter)) {
                var val = Value (typeof (string));
                model.get_value (iter, 0, out val);
                string make_and_model = null;
                if (selected_driver != null) {
                    make_and_model = selected_driver.ppd_make_and_model;
                }

                populate_driver_list_from_make (val.get_string (), make_and_model);
            }
        });

        drivers_stack.visible_child_name = "drivers";
    }

    private void populate_driver_list_from_make (string make, string? selected_make_and_model = null) {
        driver_cancellable.cancel ();
        driver_cancellable = new Cancellable ();
        driver_view.@foreach ((row) => {
            driver_view.remove (row);
        });

        find_drivers.begin (make, selected_make_and_model, (obj, res) => {
            if (!driver_cancellable.is_cancelled ()) {
                var row_to_select = find_drivers.end (res);
                driver_view.select_row (row_to_select);
            }

            driver_cancellable = null;
        });

    }

    private async Gtk.ListBoxRow? find_drivers (string make, string? selected_make_and_model) {
        Gtk.ListBoxRow? row_to_select = null;
        foreach (var driver in drivers) {
            if (driver_cancellable.is_cancelled ()) {
                return null;
            }

            if (driver.ppd_make == make) {
                var row = new DriverRow (driver);
                driver_view.add (row);
                if (driver.ppd_make_and_model == selected_make_and_model) {
                   row_to_select = row;
                }
            }

            // This greatly speeds up constructing the list and also allows the function
            // to be cancelled.
            Idle.add (find_drivers.callback);
            yield;
        }

        return row_to_select;
    }

    private static int temp_device_list_sort (TempDeviceRow row1, TempDeviceRow row2) {
        switch (row1.temp_device.device_class) {
            case "direct":
                if (row2.temp_device.device_class == "direct") {
                    return strcmp (row1.temp_device.device_info, row2.temp_device.device_info);
                } else {
                    return -1;
                }
            case "ok-network":
                if (row2.temp_device.device_class == "direct") {
                    return 1;
                } else if (row2.temp_device.device_class == "ok-network") {
                    return strcmp (row1.temp_device.device_info, row2.temp_device.device_info);
                } else {
                    return -1;
                }
            case "network":
                if (row2.temp_device.device_class == "direct") {
                    return 1;
                } else if (row2.temp_device.device_class == "ok-network") {
                    return 1;
                } else if (row2.temp_device.device_class == "network") {
                    return strcmp (row1.temp_device.device_info, row2.temp_device.device_info);
                } else {
                    return -1;
                }
            default:
                if (row2.temp_device.device_class == "direct") {
                    return 1;
                } else if (row2.temp_device.device_class == "ok-network") {
                    return 1;
                } else if (row2.temp_device.device_class == "network") {
                    return 1;
                } else {
                    return strcmp (row1.temp_device.device_info, row2.temp_device.device_info);
                }
        }
    }

    private static void temp_device_list_header (TempDeviceRow row, TempDeviceRow? before) {
        if (before == null || before.temp_device.device_class != row.temp_device.device_class) {
            switch (row.temp_device.device_class) {
                case "serial":
                    row.set_header (new Granite.HeaderLabel (_("Serial")));
                    break;
                case "direct":
                    row.set_header (new Granite.HeaderLabel (_("Local Printers")));
                    break;
                case "network":
                    row.set_header (new Granite.HeaderLabel (_("Network Printers")));
                    break;
                case "ok-network":
                    row.set_header (new Granite.HeaderLabel (_("Available Network Printers")));
                    break;
                default:
                    row.set_header (new Granite.HeaderLabel (row.temp_device.device_class));
                    break;
            }
        } else {
            row.set_header (null);
        }
    }

    public class TempDeviceRow : Gtk.ListBoxRow {
        public TempDevice temp_device { get; private set; }

        public TempDeviceRow (TempDevice temp_device) {
            this.temp_device = temp_device;

            var label = new Gtk.Label (temp_device.device_info) {
                margin_top = 3,
                margin_bottom = 3,
                margin_start = 12,
                xalign = 0
            };
            get_style_context ().add_class (Gtk.STYLE_CLASS_MENUITEM);

            child = label;
            show_all ();
        }
    }

    public class DriverRow : Gtk.ListBoxRow {
        public DeviceDriver driver { get; construct; }
        public DriverRow (DeviceDriver driver) {
            Object (driver: driver);
        }

        construct {
            var model = driver.ppd_make_and_model;
            model = model.replace ("(recommended)", _("(recommended)"));

            var model_label = new Gtk.Label (model) {
                halign = Gtk.Align.START,
                ellipsize = Pango.EllipsizeMode.MIDDLE
            };

            var detail_label = new Gtk.Label ("%s — %s".printf (driver.ppd_natural_language, driver.ppd_name)) {
                halign = Gtk.Align.START,
                ellipsize = Pango.EllipsizeMode.MIDDLE
            };

            unowned var style_context = detail_label.get_style_context ();
            style_context.add_class (Granite.STYLE_CLASS_SMALL_LABEL);
            style_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
                margin_top = 6,
                margin_start = 6,
                margin_bottom = 6,
                margin_end = 6
            };
            box.add (model_label);
            box.add (detail_label);

            child = box;
            show_all ();
        }
    }
}
