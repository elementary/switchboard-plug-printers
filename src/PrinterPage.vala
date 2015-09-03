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

public class Printers.PrinterPage : Gtk.Grid {
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

    public PrinterPage (CUPS.Destination dest) {
        expand = true;
        var image = new Gtk.Image.from_icon_name ("printer", Gtk.IconSize.DIALOG);
        var name = new Gtk.Label (dest.printer_info);
        ((Gtk.Misc) name).xalign = 0;
        var state = new Gtk.Label (human_readable_reason (dest.printer_state_reasons));
        ((Gtk.Misc) state).xalign = 0;
        attach (image, 0, 0, 1, 2);
        attach (name, 1, 0, 1, 1);
        attach (state, 1, 1, 1, 1);
        show_all ();
    }

    private string human_readable_reason (string reason) {
        for (int i = 0; i < reasons.length; i++) {
            if (reasons[i] in reason) {
                return _(statuses[i]);
            }
        }

        return reason;
    }
}

public class Printers.PrinterRow : Gtk.ListBoxRow {
    public PrinterPage page;

    public PrinterRow (CUPS.Destination dest) {
        var label = new Gtk.Label (dest.printer_info);
        var image = new Gtk.Image.from_icon_name ("printer", Gtk.IconSize.DND);
        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.HORIZONTAL;
        grid.add (image);
        grid.add (label);
        add (grid);
        page = new PrinterPage (dest);
        show_all ();
    }
}
