/*-
 * Copyright (c) 2015-2018 elementary LLC.
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

public class Printers.PrinterManager : GLib.Object {
    public const uint RENEW_INTERVAL = 500;
    public const int SUBSCRIPTION_DURATION = 600;

    private static PrinterManager printer_manager;
    public static unowned PrinterManager get_default () {
        if (printer_manager == null) {
            printer_manager = new PrinterManager ();
        }

        return printer_manager;
    }

    public signal void printer_added (Printers.Printer printer);

    private int subscription_id = -1;
    private Gee.LinkedList<Printer> printers;

    private PrinterManager () {
        printers = new Gee.LinkedList<Printer> ();
        unowned CUPS.Destination[] dests = CUPS.get_destinations ();
        foreach (unowned CUPS.Destination dest in dests) {
            add_printer (dest);
        }

        unowned Cups.Notifier notifier = Cups.Notifier.get_default ();
        notifier.printer_added.connect (printer_is_added);
        notifier.printer_deleted.connect (printer_is_deleted);
        notifier.printer_state_changed.connect (printer_state_has_changed);
        notifier.printer_modified.connect (printer_is_modified);

        new_subscription.begin ();
        Timeout.add_seconds (RENEW_INTERVAL, () => {
            new_subscription.begin ();
            return GLib.Source.CONTINUE;
        });
    }

    public unowned Gee.LinkedList<Printer> get_printers () {
        return printers;
    }

    private void printer_is_added (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs) {
        unowned CUPS.Destination[] destinations = CUPS.get_destinations ();
        foreach (unowned CUPS.Destination dest in destinations) {
            if (dest.name == name) {
                add_printer (dest);
                break;
            }
        }
    }

    private void printer_is_modified (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs) {
        Printer? found_printer = null;
        foreach (var printer in printers) {
            if (printer.dest.name == name) {
                found_printer = printer;
                break;
            }
        }

        if (found_printer == null) {
            printer_is_added (text, printer_uri, name, state, state_reasons, is_accepting_jobs);
        }
    }

    private void printer_is_deleted (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs) {
        Printer? found_printer = null;
        foreach (var printer in printers) {
            if (printer.dest.name == name) {
                found_printer = printer;
                break;
            }
        }

        if (found_printer != null) {
            printers.remove (found_printer);
            found_printer.deleted ();
        }
    }

    private void printer_state_has_changed (string text, string printer_uri, string name, uint32 state, string state_reasons, bool is_accepting_jobs) {
        foreach (var printer in printers) {
            if (printer.dest.name == name) {
                printer.notify_property ("state");
                printer.notify_property ("state-reasons");
                printer.notify_property ("state-change-time");
                break;
            }
        }
    }

    private void add_printer (CUPS.Destination destination) {
        var printer = new Printer (destination);
        printers.add (printer);
        printer_added (printer);
    }

    private const string[] SUBSCRIPTION_EVENTS = {
        "printer-added",
        "printer-deleted",
        "printer-stopped",
        "printer-state-changed",
        "job-created",
        "job-completed",
        null
    };

    private async void new_subscription () {
        CUPS.IPP.IPP request = null;
        if (subscription_id <= 0) {
            request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.CREATE_PRINTER_SUBSCRIPTION);
            request.add_strings (CUPS.IPP.Tag.SUBSCRIPTION, CUPS.IPP.Tag.KEYWORD, "notify-events", null, SUBSCRIPTION_EVENTS);
            request.add_string (CUPS.IPP.Tag.SUBSCRIPTION, CUPS.IPP.Tag.KEYWORD, "notify-pull-method", null, "ippget");
            request.add_string (CUPS.IPP.Tag.SUBSCRIPTION, CUPS.IPP.Tag.URI, "notify-recipient-uri", null, "dbus://");
        } else {
            request = new CUPS.IPP.IPP.request (CUPS.IPP.Operation.RENEW_SUBSCRIPTION);
            request.add_integer (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.INTEGER, "notify-subscription-id", subscription_id);
        }

        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.URI, "printer-uri", null, "/");
        request.add_string (CUPS.IPP.Tag.OPERATION, CUPS.IPP.Tag.NAME, "requesting-user-name", null, CUPS.get_user ());
        request.add_integer (CUPS.IPP.Tag.SUBSCRIPTION, CUPS.IPP.Tag.INTEGER, "notify-lease-duration", SUBSCRIPTION_DURATION);
        request.do_request (CUPS.HTTP.DEFAULT);
        if (request != null && request.get_status_code () <= CUPS.IPP.Status.OK_CONFLICT) {
            unowned CUPS.IPP.Attribute attr = request.find_attribute ("notify-subscription-id", CUPS.IPP.Tag.INTEGER);
            if (attr != null) {
                subscription_id = attr.get_integer ();
            } else {
                critical ("No notify-subscription-id in response!");
            }
        }
    }
}
