/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018 elementary, Inc. (https://elementary.io)
 */

public class Printers.RemoveDialog : Granite.MessageDialog {
    public Printer printer { get; construct; }

    public RemoveDialog (Printer printer) {
        Object (
            buttons: Gtk.ButtonsType.CANCEL,
            image_icon: new ThemedIcon ("dialog-question"),
            modal: true,
            printer: printer,
            primary_text: _("Are You Sure You Want To Remove '%s'?").printf (printer.info),
            secondary_text: _("By removing '%s' you'll lose all print history and configuration associated with it.").printf (printer.info)
        );
    }

    construct {
        var button = add_button (_("Remove"), 0);
        button.add_css_class (Granite.STYLE_CLASS_DESTRUCTIVE_ACTION);

        response.connect (on_response);
    }

    private void on_response (Gtk.Dialog source, int response_id) {
        if (response_id == 0) {
            try {
                Cups.get_pk_helper ().printer_delete (printer.dest.name);
            } catch (Error e) {
                critical (e.message);
            }
        }
        destroy ();
    }
}
