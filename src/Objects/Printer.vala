// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright 2015 - 2022 elementary, Inc. (https://elementary.io)
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

public class Printers.Printer : GLib.Object {
    private static string[] reasons = {
        "toner-low",
        "toner-empty",
        "developer-low",
        "developer-empty",
        "marker-supply-low",
        "marker-supply-empty",
        "cover-open",
        "door-open",
        "media-low",
        "media-empty",
        "offline",
        "paused",
        "marker-waste-almost-full",
        "marker-waste-full",
        "opc-near-eol",
        "opc-life-over"
    };

    private static string[] statuses = {
        /// Translators: The printer is low on toner
        NC_("printer state", "Low on toner"),
        /// Translators: The printer has no toner left
        NC_("printer state", "Out of toner"),
        /// Translators: "Developer" is a chemical for photo development, http://en.wikipedia.org/wiki/Photographic_developer
        NC_("printer state", "Low on developer"),
        /// Translators: "Developer" is a chemical for photo development, http://en.wikipedia.org/wiki/Photographic_developer
        NC_("printer state", "Out of developer"),
        /// Translators: "marker" is one color bin of the printer
        NC_("printer state", "Low on a marker supply"),
        /// Translators: "marker" is one color bin of the printer
        NC_("printer state", "Out of a marker supply"),
        /// Translators: One or more covers on the printer are open
        NC_("printer state", "Open cover"),
        /// Translators: One or more doors on the printer are open
        NC_("printer state", "Open door"),
        /// Translators: At least one input tray is low on media
        NC_("printer state", "Low on paper"),
        /// Translators: At least one input tray is empty
        NC_("printer state", "Out of paper"),
        /// Translators: The printer is offline
        NC_("printer state", "Offline"),
        /// Translators: Someone has stopped the Printer
        NC_("printer state", "Stopped"),
        /// Translators: The printer marker supply waste receptacle is almost full
        NC_("printer state", "Waste receptacle almost full"),
        /// Translators: The printer marker supply waste receptacle is full
        NC_("printer state", "Waste receptacle full"),
        /// Translators: Optical photo conductors are used in laser printers
        NC_("printer state", "The optical photo conductor is near end of life"),
        /// Translators: Optical photo conductors are used in laser printers
        NC_("printer state", "The optical photo conductor is no longer functioning")
    };

    public class ColorLevel {
        public int level;
        public int level_max;
        public int level_min;
        public string color;
        public string name;
    }

    /***********
     * Signals *
     ***********/
    public signal void enabled_changed ();
    public signal void default_changed ();
    public signal void deleted ();

    /**************
     * Properties *
     **************/
    public bool is_enabled {
        get {
            return state != "5";
        }

        set {
            if (value == (state == "5")) {
                try {
                    Cups.get_pk_helper ().printer_set_enabled (dest.name, value);
                    // Cups.get_pk_helper ().printer_set_enabled (dest.name, false);
                } catch (Error e) {
                    critical (e.message);
                }

                try {
                    Cups.get_pk_helper ().printer_set_accept_jobs (dest.name, value);
                } catch (Error e) {
                    critical (e.message);
                }
            }
        }
    }

    public bool is_default {
        get {
            return dest.is_default;
        }

        set {
            if (value == true) {
                try {
                    Cups.get_pk_helper ().printer_set_default (dest.name);
                    default_changed ();
                } catch (Error e) {
                    critical (e.message);
                }
            }
        }
    }

    /**
     * The type of authentication required for printing to this destination:
     * "none", "username,password", "domain,username,password", or "negotiate" (Kerberos)
     */
    public string auth_info_required {
        get {
            return CUPS.get_option ("auth-info-required", dest.options) ?? "none";
        }
    }

    /**
     * The human-readable description of the destination such as "My Laser Printer".
     */
    public string info {
        get {
            return CUPS.get_option ("printer-info", dest.options) ?? _("Unnamed Printer");
        }
        set {
            try {
                Cups.get_pk_helper ().printer_set_info (dest.name, value);
                dest.num_options = CUPS.add_option ("printer-info", value, dest.options.length, ref dest.options);
            } catch (Error e) {
                critical (e.message);
            }
        }
    }


     public bool is_accepting_jobs { get; set construct; }

     // "3" if the destination is idle, "4" if the destination is printing a job, and "5" if the destination is stopped.
    public string state { get; set construct; }

    public bool is_shared {
        get {
            unowned string? cups_result = CUPS.get_option ("printer-is-shared", dest.options);
            if (cups_result == null) {
                return false;
            }

            return bool.parse (cups_result);
        }
        set {
            try {
                Cups.get_pk_helper ().printer_set_shared (dest.name, value);
                dest.num_options = CUPS.add_option ("printer-is-shared", value.to_string (), dest.options.length, ref dest.options);
            } catch (Error e) {
                critical (e.message);
            }
        }
    }

    /**
     * The human-readable location of the destination such as "Lab 4".
     */
    public string location {
        get {
            return CUPS.get_option ("printer-location", dest.options) ?? "";
        }
        set {
            try {
                Cups.get_pk_helper ().printer_set_location (dest.name, value);
                dest.num_options = CUPS.add_option ("printer-location", value, dest.options.length, ref dest.options);
            } catch (Error e) {
                critical (e.message);
            }
        }
    }

    /**
     * The human-readable make and model of the destination such as "HP LaserJet 4000 Series".
     */
    public string? make_and_model {
        get {
            return CUPS.get_option ("printer-make-and-model", dest.options);
        }
    }

    /**
     * Additional comma-delimited state keywords for the destination such as "media-tray-empty-error" and "toner-low-warning".
     */
    public string? state_reasons_raw { get; set construct; }

    // Translated reasons
    public string state_reasons {
        get {
            unowned string? reason = state_reasons_raw;
            if (reason == null || reason.up ().contains ("NONE")) {
                return _("Ready");
            }

            for (int i = 0; i < reasons.length; i++) {
                if (reasons[i] in reason) {
                    return dpgettext2 (Build.GETTEXT_PACKAGE, "printer state", statuses[i]);
                }
            }

            return reason;
        }
    }

    /**
     * The cups_printer_t value associated with the destination.
     */
    public string? printer_type {
        get {
            return CUPS.get_option ("printer-type", dest.options);
        }
    }

    public unowned CUPS.Destination dest;

    /***********
     * Methods *
     ***********/
    public Printer (CUPS.Destination? dest) {
        this.dest = dest;

        // Dest.options does not seem to get updated automatically so we copy key values and use CUPS.Notifier to
        // update them when they change.
        var is_accepting_opt = CUPS.get_option ("is-accepting-jobs", dest.options);
        is_accepting_jobs = is_accepting_opt != null ? bool.parse (is_accepting_opt) : false;
        state = CUPS.get_option ("printer-state", dest.options);
        state_reasons_raw = CUPS.get_option ("printer-state-reasons", dest.options);
    }

    public bool is_offline {
        get {
            return state_reasons_raw != null ? "offline" in state_reasons_raw : false;
        }
    }

    public Gee.TreeSet<Job> get_jobs (bool my_jobs, CUPS.WhichJobs whichjobs) {
        var jobs = new Gee.TreeSet<Job> ();
        unowned CUPS.Job[] cjobs = dest.get_jobs (my_jobs, whichjobs);
        foreach (unowned CUPS.Job cjob in cjobs) {
            var job = new Job (cjob, this);
            jobs.add (job);
        }

        return jobs;
    }

    public int get_pages_per_sheet (Gee.TreeSet<int> pages_per_sheet) {
        string[] attributes = { CUPS.Attributes.NUMBER_UP_SUPPORTED,
                                CUPS.Attributes.NUMBER_UP_DEFAULT };
        try {
            var request = request_attributes (attributes);
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.NUMBER_UP_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                pages_per_sheet.add (attr.get_integer (i));
            }

            attr = request.find_attribute (CUPS.Attributes.NUMBER_UP_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_integer ();
            }
        } catch (Error e) {
            critical ("Error: %s", e.message);
        }

        return 1;
    }

    public void set_default_pages (string new_default) {
        unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, "number-up");
            pk_helper.printer_add_option_default (dest.name, "number-up", {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public string get_sides (Gee.TreeSet<string> sides) {
        string[] attributes = { CUPS.Attributes.SIDES_SUPPORTED,
                                CUPS.Attributes.SIDES_DEFAULT };
        try {
            var request = request_attributes (attributes);
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.SIDES_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                sides.add (attr.get_string (i));
            }

            attr = request.find_attribute (CUPS.Attributes.SIDES_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_string ();
            }
        } catch (Error e) {
            critical ("Error: %s", e.message);
        }

        return CUPS.Attributes.Sided.ONE;
    }

    public void set_default_side (string new_default) {
        unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, "sides");
            pk_helper.printer_add_option_default (dest.name, "sides", {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public int get_orientations (Gee.TreeSet<int> orientations) {
        string[] attributes = { CUPS.Attributes.ORIENTATION_SUPPORTED,
                                CUPS.Attributes.ORIENTATION_DEFAULT };
        try {
            var request = request_attributes (attributes);
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.ORIENTATION_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                orientations.add (attr.get_integer (i));
            }

            attr = request.find_attribute (CUPS.Attributes.ORIENTATION_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                int page = attr.get_integer ();
                if (page >= 3 && page <= 6) {
                    return page;
                }
            }
        } catch (Error e) {
            critical ("Error: %s", e.message);
        }

        return CUPS.Attributes.Orientation.PORTRAIT;
    }

    public void set_default_orientation (string new_default) {
        unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, "orientation-requested");
            pk_helper.printer_add_option_default (dest.name, "orientation-requested", {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public string get_output_bins (Gee.TreeSet<string> output_bins) {
        string[] attributes = { CUPS.Attributes.OUTPUT_BIN_SUPPORTED,
                                CUPS.Attributes.OUTPUT_BIN_DEFAULT };
        try {
            var request = request_attributes (attributes);
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.OUTPUT_BIN_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                output_bins.add (attr.get_string (i));
            }

            attr = request.find_attribute (CUPS.Attributes.OUTPUT_BIN_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_string ();
            }
        } catch (Error e) {
            critical ("Error: %s", e.message);
        }

        return "rear";
    }

    public void set_default_output_bin (string new_default) {
        unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, "output-bin");
            pk_helper.printer_add_option_default (dest.name, "output-bin", {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public string get_print_color_modes (Gee.TreeSet<string> print_color_modes) {
        string[] attributes = { CUPS.Attributes.PRINT_COLOR_MODE_SUPPORTED,
                                CUPS.Attributes.PRINT_COLOR_MODE_DEFAULT };
        try {
            var request = request_attributes (attributes);
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.PRINT_COLOR_MODE_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                print_color_modes.add (attr.get_string (i));
            }

            attr = request.find_attribute (CUPS.Attributes.PRINT_COLOR_MODE_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_string ();
            }
        } catch (Error e) {
            critical ("Error: %s", e.message);
        }

        return "auto";
    }

    public void set_default_print_color_mode (string new_default) {
        unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, "print-color-mode");
            pk_helper.printer_add_option_default (dest.name, "print-color-mode", {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public string get_media_sources (Gee.TreeSet<string> media_sources) {
        string[] attributes = { CUPS.Attributes.MEDIA_SOURCE_SUPPORTED,
                                CUPS.Attributes.MEDIA_SOURCE_DEFAULT };
        try {
            var request = request_attributes (attributes);
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.MEDIA_SOURCE_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                media_sources.add (attr.get_string (i));
            }

            attr = request.find_attribute (CUPS.Attributes.MEDIA_SOURCE_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_string ();
            }
        } catch (Error e) {
            critical ("Error: %s", e.message);
        }

        return "auto";
    }

    public string get_media_sizes (Gee.TreeSet<string> media_sizes) {
        string[] attributes = { CUPS.Attributes.MEDIA_SUPPORTED,
                                CUPS.Attributes.MEDIA_DEFAULT };
        try {
            var request = request_attributes (attributes);
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.MEDIA_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                media_sizes.add (attr.get_string (i));
            }

            attr = request.find_attribute (CUPS.Attributes.MEDIA_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_string ();
            }
        } catch (Error e) {
            critical ("Error: %s", e.message);
        }

        return Gtk.PaperSize.get_default ().dup ();
    }

    public void set_default_media_size (string new_default) {
        unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, CUPS.Attributes.MEDIA_DEFAULT);
            pk_helper.printer_add_option_default (dest.name, CUPS.Attributes.MEDIA_DEFAULT, {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public void set_default_media_source (string new_default) {
        unowned Cups.PkHelper pk_helper = Cups.get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, CUPS.Attributes.MEDIA_SOURCE_DEFAULT);
            pk_helper.printer_add_option_default (dest.name, CUPS.Attributes.MEDIA_SOURCE_DEFAULT, {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public int get_print_qualities (Gee.TreeSet<int> print_qualities) {
        string[] attributes = { CUPS.Attributes.PRINT_QUALITY_SUPPORTED,
                                CUPS.Attributes.PRINT_QUALITY_DEFAULT };
        try {
            var request = request_attributes (attributes);
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.PRINT_QUALITY_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                print_qualities.add (attr.get_integer (i));
            }

            attr = request.find_attribute (CUPS.Attributes.PRINT_QUALITY_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                int quality = attr.get_integer ();
                if (quality >= 3 && quality <= 5) {
                    return quality;
                }
            }
        } catch (Error e) {
            critical ("Error: %s", e.message);
        }

        return 4;
    }

    public void get_all () {
        string[] attributes = { "all" };
        try {
            var request = request_attributes (attributes);
            unowned CUPS.IPP.Attribute attr = request.first_attribute ();
            while (attr != null) {
                debug (attr.get_name ());
                attr = request.next_attribute ();
            }
        } catch (Error e) {
            critical ("Error: %s", e.message);
        }
    }

    private CUPS.IPP.IPP request_attributes (string[] attributes) throws GLib.Error {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        var status_code = request.get_status_code ();
        if (status_code <= CUPS.IPP.Status.OK_CONFLICT) {
            return request;
        } else {
            throw new GLib.IOError.FAILED (status_code.to_string ());
        }
    }

    public Gee.ArrayList<ColorLevel?> get_color_levels () {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        const string[] ATTRIBUTES = { "marker-colors",
                                      "marker-levels",
                                      "marker-names",
                                      "marker-high-levels",
                                      "marker-low-levels" };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, ATTRIBUTES);
        request.do_request (CUPS.HTTP.DEFAULT);

        var found_colors = new Gee.ArrayList<ColorLevel?> ();
        var status_code = request.get_status_code ();
        if (status_code <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute ("marker-colors", CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                var color = new ColorLevel ();
                color.color = attr.get_string (i);
                found_colors.add (color);
            }

            var color_size = found_colors.size;

            attr = request.find_attribute ("marker-levels", CUPS.IPP.Tag.ZERO);
            int bound = int.min (attr.get_count (), color_size);
            for (int i = 0; i < bound; i++) {
                found_colors[i].level = attr.get_integer (i);
            }

            attr = request.find_attribute ("marker-high-levels", CUPS.IPP.Tag.ZERO);
            bound = int.min (attr.get_count (), color_size);
            for (int i = 0; i < bound; i++) {
                found_colors[i].level_max = attr.get_integer (i);
            }

            attr = request.find_attribute ("marker-low-levels", CUPS.IPP.Tag.ZERO);
            bound = int.min (attr.get_count (), color_size);
            for (int i = 0; i < bound; i++) {
                found_colors[i].level_min = attr.get_integer (i);
            }

            attr = request.find_attribute ("marker-names", CUPS.IPP.Tag.ZERO);
            bound = int.min (attr.get_count (), color_size);
            for (int i = 0; i < bound; i++) {
                found_colors[i].name = attr.get_string (i).dup ();
            }
        } else {
            critical ("Error: %s", status_code.to_string ());
        }

        found_colors.sort ((a, b) => {
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

        return found_colors;
    }
}
