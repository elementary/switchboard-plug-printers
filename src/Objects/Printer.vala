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

public class Printers.Printer : GLib.Object {
    private static Cups.PkHelper pk_helper = null;
    public static unowned Cups.PkHelper get_pk_helper () {
        if (pk_helper == null) {
            try {
                pk_helper = Bus.get_proxy_sync (BusType.SYSTEM, "org.opensuse.CupsPkHelper.Mechanism", "/");
            } catch (IOError e) {
                critical (e.message);
            }
        }

        return pk_helper;
    }

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
        N_("Low on toner"),
        /// Translators: The printer has no toner left
        N_("Out of toner"),
        /// Translators: "Developer" is a chemical for photo development, http://en.wikipedia.org/wiki/Photographic_developer
        N_("Low on developer"),
        /// Translators: "Developer" is a chemical for photo development, http://en.wikipedia.org/wiki/Photographic_developer
        N_("Out of developer"),
        /// Translators: "marker" is one color bin of the printer
        N_("Low on a marker supply"),
        /// Translators: "marker" is one color bin of the printer
        N_("Out of a marker supply"),
        /// Translators: One or more covers on the printer are open
        N_("Open cover"),
        /// Translators: One or more doors on the printer are open
        N_("Open door"),
        /// Translators: At least one input tray is low on media
        N_("Low on paper"),
        /// Translators: At least one input tray is empty
        N_("Out of paper"),
        /// Translators: The printer is offline
        NC_("printer state", "Offline"),
        /// Translators: Someone has stopped the Printer
        NC_("printer state", "Stopped"),
        /// Translators: The printer marker supply waste receptacle is almost full
        N_("Waste receptacle almost full"),
        /// Translators: The printer marker supply waste receptacle is full
        N_("Waste receptacle full"),
        /// Translators: Optical photo conductors are used in laser printers
        N_("The optical photo conductor is near end of life"),
        /// Translators: Optical photo conductors are used in laser printers
        N_("The optical photo conductor is no longer functioning")
    };

    /***********
     * Signals *
     ***********/
    public signal void enabled_changed ();
    public signal void default_changed ();

    /**************
     * Properties *
     **************/
    public bool enabled {
        get {
            return state != "5" && is_accepting_jobs;
        }

        set {
            if (!value) {
                try {
                    get_pk_helper ().printer_set_enabled (dest.name, false);
                } catch (Error e) {
                    critical (e.message);
                }

                try {
                    get_pk_helper ().printer_set_accept_jobs (dest.name, false);
                } catch (Error e) {
                    critical (e.message);
                }

                enabled_changed ();
            } else {
                if (state == "5") {
                    try {
                        get_pk_helper ().printer_set_enabled (dest.name, true);
                    } catch (Error e) {
                        critical (e.message);
                    }
                }

                if (is_accepting_jobs == false) {
                    try {
                        get_pk_helper ().printer_set_accept_jobs (dest.name, true);
                    } catch (Error e) {
                        critical (e.message);
                    }
                }

                enabled_changed ();
            }
        }
    }

    public bool is_default {
        get {
            return dest.is_default;
        }

        set {
            if (value == true) {
                get_pk_helper ().printer_set_default (dest.name);
                default_changed ();
            }
        }
    }

    /**
     * The type of authentication required for printing to this destination:
     * "none", "username,password", "domain,username,password", or "negotiate" (Kerberos)
     */
    public string auth_info_required {
        get {
            return CUPS.get_option ("auth-info-required", dest.options);
        }
    }

    /**
     * The human-readable description of the destination such as "My Laser Printer".
     */
    public string info {
        get {
            return CUPS.get_option ("printer-info", dest.options);
        }
        set {
            get_pk_helper ().printer_set_info (dest.name, value);
            dest.num_options = CUPS.add_option ("printer-info", value, dest.options.length, ref dest.options);
        }
    }

    /**
     * "true" if the destination is accepting new jobs, "false" if not.
     */
    public bool is_accepting_jobs {
        get {
            return bool.parse (CUPS.get_option ("printer-is-accepting-jobs", dest.options));
        }
        set {
            get_pk_helper ().printer_set_accept_jobs (dest.name, value);
            dest.num_options = CUPS.add_option ("printer-is-accepting-jobs", value.to_string (), dest.options.length, ref dest.options);
        }
    }

    /**
     * "true" if the destination is being shared with other computers, "false" if not.
     */
    public bool is_shared {
        get {
            return bool.parse (CUPS.get_option ("printer-is-shared", dest.options));
        }
        set {
            get_pk_helper ().printer_set_shared (dest.name, value);
            dest.num_options = CUPS.add_option ("printer-is-shared", value.to_string (), dest.options.length, ref dest.options);
        }
    }

    /**
     * The human-readable location of the destination such as "Lab 4".
     */
    public string location {
        get {
            return CUPS.get_option ("printer-location", dest.options);
        }
        set {
            get_pk_helper ().printer_set_location (dest.name, value);
            dest.num_options = CUPS.add_option ("printer-location", value, dest.options.length, ref dest.options);
        }
    }

    /**
     * The human-readable make and model of the destination such as "HP LaserJet 4000 Series".
     */
    public string make_and_model {
        get {
            return CUPS.get_option ("printer-make-and-model", dest.options);
        }
    }

    /**
     * "3" if the destination is idle, "4" if the destination is printing a job, and "5" if the destination is stopped.
     */
    public string state {
        get {
            return CUPS.get_option ("printer-state", dest.options);
        }
    }

    /**
     * The UNIX time when the destination entered the current state.
     */
    public string state_change_time {
        get {
            return CUPS.get_option ("printer-state-change-time", dest.options);
        }
    }

    /**
     * Additional comma-delimited state keywords for the destination such as "media-tray-empty-error" and "toner-low-warning".
     */
    public string state_reasons {
        get {
            return CUPS.get_option ("printer-state-reasons", dest.options);
        }
    }

    public string state_reasons_localized {
        get {
            unowned string reason = state_reasons;
            for (int i = 0; i < reasons.length; i++) {
                if (reasons[i] in reason) {
                    return _(statuses[i]);
                }
            }

            if (reason == "none") {
                return _("Ready");
            }

            return reason;
        }
    }

    /**
     * The cups_printer_t value associated with the destination.
     */
    public string printer_type {
        get {
            return CUPS.get_option ("printer-type", dest.options);
        }
    }

    public unowned CUPS.Destination dest;

    /***********
     * Methods *
     ***********/
    public Printer (CUPS.Destination dest) {
        this.dest = dest;
    }

    public Gee.TreeSet<Job> get_jobs (bool my_jobs, CUPS.WhichJobs whichjobs) {
        var jobs = new Gee.TreeSet<Job> ();
        unowned CUPS.Job[] cjobs = dest.get_jobs (my_jobs, whichjobs);
        foreach (unowned CUPS.Job cjob in cjobs) {
            var job = new Job (cjob);
            jobs.add (job);
        }

        return jobs;
    }

    public int get_pages_per_sheet (Gee.TreeSet<int> pages_per_sheet) {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        string[] attributes = { CUPS.Attributes.NUMBER_UP_SUPPORTED,
                                CUPS.Attributes.NUMBER_UP_DEFAULT };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.NUMBER_UP_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                pages_per_sheet.add (attr.get_integer (i));
            }

            attr = request.find_attribute (CUPS.Attributes.NUMBER_UP_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_integer ();
            } else {
                return 1;
            }
        } else {
            critical ("Error: %s", request.get_status_code ().to_string ());
            return -1;
        }
    }

    public void set_default_pages (string new_default) {
        unowned Cups.PkHelper pk_helper = get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, "number-up");
            pk_helper.printer_add_option_default (dest.name, "number-up", {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public string get_sides (Gee.TreeSet<string> sides) {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        string[] attributes = { CUPS.Attributes.SIDES_SUPPORTED,
                                CUPS.Attributes.SIDES_DEFAULT };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.SIDES_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                sides.add (attr.get_string (i));
            }

            attr = request.find_attribute (CUPS.Attributes.SIDES_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_string ();
            } else {
                return CUPS.Attributes.Sided.ONE;
            }
        } else {
            critical ("Error: %s", request.get_status_code ().to_string ());
            return "";
        }
    }

    public void set_default_side (string new_default) {
        unowned Cups.PkHelper pk_helper = get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, "sides");
            pk_helper.printer_add_option_default (dest.name, "sides", {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public int get_orientations (Gee.TreeSet<int> orientations) {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        string[] attributes = { CUPS.Attributes.ORIENTATION_SUPPORTED,
                                CUPS.Attributes.ORIENTATION_DEFAULT };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.ORIENTATION_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                orientations.add (attr.get_integer (i));
            }

            attr = request.find_attribute (CUPS.Attributes.ORIENTATION_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                int page = attr.get_integer ();
                if (page >= 3 && page <= 6) {
                    return page;
                } else {
                    return CUPS.Attributes.Orientation.PORTRAIT;
                }
            } else {
                return CUPS.Attributes.Orientation.PORTRAIT;
            }
        } else {
            critical ("Error: %s", request.get_status_code ().to_string ());
            return -1;
        }
    }

    public void set_default_orientation (string new_default) {
        unowned Cups.PkHelper pk_helper = get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, "orientation-requested");
            pk_helper.printer_add_option_default (dest.name, "orientation-requested", {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public string get_output_bins (Gee.TreeSet<string> output_bins) {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        string[] attributes = { CUPS.Attributes.OUTPUT_BIN_SUPPORTED,
                                CUPS.Attributes.OUTPUT_BIN_DEFAULT };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.OUTPUT_BIN_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                output_bins.add (attr.get_string (i));
            }

            attr = request.find_attribute (CUPS.Attributes.OUTPUT_BIN_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_string ();
            } else {
                return "rear";
            }
        } else {
            critical ("Error: %s", request.get_status_code ().to_string ());
            return "";
        }
    }

    public void set_default_output_bin (string new_default) {
        unowned Cups.PkHelper pk_helper = get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, "output-bin");
            pk_helper.printer_add_option_default (dest.name, "output-bin", {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public string get_print_color_modes (Gee.TreeSet<string> print_color_modes) {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        string[] attributes = { CUPS.Attributes.PRINT_COLOR_MODE_SUPPORTED,
                                CUPS.Attributes.PRINT_COLOR_MODE_DEFAULT };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.PRINT_COLOR_MODE_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                print_color_modes.add (attr.get_string (i));
            }

            attr = request.find_attribute (CUPS.Attributes.PRINT_COLOR_MODE_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_string ();
            } else {
                return "auto";
            }
        } else {
            critical ("Error: %s", request.get_status_code ().to_string ());
            return "";
        }
    }

    public void set_default_print_color_mode (string new_default) {
        unowned Cups.PkHelper pk_helper = get_pk_helper ();
        try {
            pk_helper.printer_delete_option_default (dest.name, "print-color-mode");
            pk_helper.printer_add_option_default (dest.name, "print-color-mode", {new_default});
        } catch (Error e) {
            critical (e.message);
        }
    }

    public string get_media_sources (Gee.TreeSet<string> media_sources) {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        string[] attributes = { CUPS.Attributes.MEDIA_SOURCE_SUPPORTED,
                                CUPS.Attributes.MEDIA_SOURCE_DEFAULT };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.MEDIA_SOURCE_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                media_sources.add (attr.get_string (i));
            }

            attr = request.find_attribute (CUPS.Attributes.MEDIA_SOURCE_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                return attr.get_string ();
            } else {
                return "auto";
            }
        } else {
            critical ("Error: %s", request.get_status_code ().to_string ());
            return "";
        }
    }

    public void set_default_media_source (string new_default) {
        //TODO
    }

    public int get_print_qualities (Gee.TreeSet<int> print_qualities) {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        string[] attributes = { CUPS.Attributes.PRINT_QUALITY_SUPPORTED,
                                CUPS.Attributes.PRINT_QUALITY_DEFAULT };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute (CUPS.Attributes.PRINT_QUALITY_SUPPORTED, CUPS.IPP.Tag.ZERO);
            for (int i = 0; i < attr.get_count (); i++) {
                print_qualities.add (attr.get_integer (i));
            }

            attr = request.find_attribute (CUPS.Attributes.PRINT_QUALITY_DEFAULT, CUPS.IPP.Tag.ZERO);
            if (attr.get_count () > 0) {
                int quality = attr.get_integer ();
                if (quality >= 3 && quality <= 5) {
                    return quality;
                } else {
                    return 4;
                }
            } else {
                return 4;
            }
        } else {
            critical ("Error: %s", request.get_status_code ().to_string ());
            return -1;
        }
    }

    public void get_all () {
        char[] printer_uri = new char[CUPS.HTTP.MAX_URI];
        CUPS.HTTP.assemble_uri_f (CUPS.HTTP.URICoding.QUERY, printer_uri, "ipp", null, "localhost", 0, "/printers/%s", dest.name);
        var request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.GET_PRINTER_ATTRIBUTES);
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, (string)printer_uri);

        string[] attributes = { "all" };

        request.add_strings (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.KEYWORD, "requested-attributes", null, attributes);
        request.do_request (CUPS.HTTP.DEFAULT);

        if (request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.first_attribute ();
            while (attr != null) {
                warning (attr.get_name ());
                attr = request.next_attribute ();
            }
        } else {
            critical ("Error: %s", request.get_status_code ().to_string ());
        }
    }
}
