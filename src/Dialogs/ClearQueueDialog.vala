/*-
 * Copyright (c) 2022 elementary LLC. (https://elementary.io)
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
 */

public class Printers.ClearQueueDialog : Granite.MessageDialog {
    public Printer printer { get; construct; }

    public ClearQueueDialog (Printer printer) {
        Object (
            buttons: Gtk.ButtonsType.CANCEL,
            image_icon: new ThemedIcon ("edit-clear"),
            badge_icon: new ThemedIcon ("dialog-question"),
            modal: true,
            printer: printer,
            primary_text: _("Clear all pending and completed jobs from “%s”?").printf (printer.info),
            secondary_text: _("All unfinished jobs will be canceled and all print history will be erased.")
        );
    }

    construct {
        var button = add_button (_("Clear All"), Gtk.ResponseType.OK);
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
    }
}
