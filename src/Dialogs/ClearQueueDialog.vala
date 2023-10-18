/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022 elementary, Inc. (https://elementary.io)
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
        button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);
    }
}
